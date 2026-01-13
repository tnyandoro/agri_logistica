# app/controllers/api/v1/shipments_controller.rb
module Api
  module V1
    class ShipmentsController < BaseController
      before_action :authenticate_user!
      before_action :set_shipment, only: [:show, :update, :destroy, :accept, :complete, :cancel]

      # GET /api/v1/shipments
      def index
        shipments = Shipment.includes(:produce_listing, :trucking_company)
                            .order(created_at: :desc)
        shipments = filter_by_role(shipments)
        paginated = paginate(shipments)

        render json: {
          success: true,
          data: paginated.map { |s| ShipmentSerializer.new(s).as_json },
          pagination: pagination_meta(paginated)
        }
      end

      # GET /api/v1/shipments/available
      def available
        shipments = Shipment.where(status: 'pending').order(created_at: :asc)
        paginated = paginate(shipments)

        render json: {
          success: true,
          data: paginated.map { |s| ShipmentSerializer.new(s, include_bids: true).as_json },
          pagination: pagination_meta(paginated)
        }
      end

      # GET /api/v1/shipments/my_shipments
      def my_shipments
        shipments = case current_user.user_role
                    when 'farmer'
                      current_user.farmer_profile.shipments
                    when 'trucker'
                      current_user.trucking_company.shipments
                    when 'market'
                      Shipment.joins(:produce_request)
                              .where(produce_requests: { market_profile_id: current_user.market_profile.id })
                    else
                      Shipment.none
                    end

        paginated = paginate(shipments.order(created_at: :desc))
        render json: {
          success: true,
          data: paginated.map { |s| ShipmentSerializer.new(s, include_bids: true).as_json },
          pagination: pagination_meta(paginated)
        }
      end

      # GET /api/v1/shipments/:id
      def show
        render json: {
          success: true,
          data: ShipmentSerializer.new(@shipment, include_bids: true).as_json
        }
      end

      # POST /api/v1/shipments
      def create
        # Find the produce request
        produce_request = ProduceRequest.find(params[:produce_request_id])
        produce_listing = produce_request.produce_listing

        # Initialize shipment (not saved yet)
        shipment = Shipment.new(shipment_params)
        shipment.status = 'pending'
        shipment.produce_request = produce_request
        shipment.produce_listing ||= produce_listing

        # Calculate distance if lat/long available
        if produce_listing.latitude && produce_request.market_profile.latitude
          shipment.distance_km = Geocoder::Calculations.distance_between(
            [produce_listing.latitude, produce_listing.longitude],
            [produce_request.market_profile.latitude, produce_request.market_profile.longitude]
          ).round(2)
        end

        # Calculate agreed price based on distance
        shipment.agreed_price ||= shipment.calculate_shipping_cost(shipment.distance_km)

        if params[:preview].to_s == 'true'
          # For preview: do not save, just return calculated info
          render json: {
            success: true,
            preview: true,
            message: 'Shipment cost and distance preview',
            data: {
              distance_km: shipment.distance_km,
              agreed_price: shipment.agreed_price,
              pickup_location: shipment.pickup_location,
              delivery_location: shipment.delivery_location
            }
          }
        else
          # Save normally
          if shipment.save
            render json: {
              success: true,
              message: 'Shipment created successfully',
              data: ShipmentSerializer.new(shipment).as_json
            }, status: :created
          else
            render_error('Failed to create shipment', errors: shipment.errors.full_messages)
          end
        end
      end

      # PATCH /api/v1/shipments/:id
      def update
        # Only certain roles can update certain fields
        if @shipment.update(shipment_params)
          render json: {
            success: true,
            message: 'Shipment updated successfully',
            data: ShipmentSerializer.new(@shipment).as_json
          }
        else
          render_error('Failed to update shipment', errors: @shipment.errors.full_messages)
        end
      end

    # PATCH /api/v1/shipments/:id/accept
      def accept
        authorize_trucker!
        if @shipment.pending?
          @shipment.update!(status: 'in_transit', trucking_company: current_user.trucking_company)

          # Notify market
          NotificationService.notify_market_of_shipment_acceptance(@shipment)

          render json: { success: true, message: 'Shipment accepted, now in transit', data: ShipmentSerializer.new(@shipment).as_json }
        else
          render_error('Shipment cannot be accepted')
        end
      end

      # PATCH /api/v1/shipments/:id/cancel
      def cancel
        if @shipment.pending? && (current_user.user_role.in?(%w[market farmer]))
          @shipment.update!(status: 'cancelled')

          # Notify market
          NotificationService.notify_market_of_shipment_cancellation(@shipment)

          render json: { success: true, message: 'Shipment cancelled', data: ShipmentSerializer.new(@shipment).as_json }
        else
          render_error('Cannot cancel shipment at this stage')
        end
      end


      # PATCH /api/v1/shipments/:id/complete
      def complete
        authorize_trucker!
        if @shipment.in_transit?
          @shipment.update!(status: 'delivered')
          render json: {
            success: true,
            message: 'Shipment marked as delivered',
            data: ShipmentSerializer.new(@shipment).as_json
          }
        else
          render_error('Shipment cannot be completed')
        end
      end

      # PATCH /api/v1/shipments/:id/cancel
      # def cancel
      #   if @shipment.pending? && (current_user.user_role == 'market' || current_user.user_role == 'farmer')
      #     @shipment.update!(status: 'cancelled')
      #     render json: {
      #       success: true,
      #       message: 'Shipment cancelled',
      #       data: ShipmentSerializer.new(@shipment).as_json
      #     }
      #   else
      #     render_error('Cannot cancel shipment at this stage')
      #   end
      # end

      # DELETE /api/v1/shipments/:id
      def destroy
        if current_user.user_role == 'market' || current_user.user_role == 'farmer'
          @shipment.destroy
          render json: { success: true, message: 'Shipment deleted successfully' }
        else
          render_error('Unauthorized', status: :forbidden)
        end
      end

      private

      def set_shipment
        @shipment = Shipment.find(params[:id])
      end

      def shipment_params
        params.require(:shipment).permit(
          :pickup_location, :delivery_location, :pickup_date,
          :delivery_date, :cargo_type, :cargo_weight,
          :special_requirements, :budget
        )
      end

      def filter_by_role(shipments)
        case current_user.user_role
        when 'farmer'
          shipments.where(farmer_profile: current_user.farmer_profile)
        when 'trucker'
          shipments.where(trucking_company: current_user.trucking_company)
        when 'market'
          shipments.joins(:produce_request).where(produce_requests: { market_profile_id: current_user.market_profile.id })
        else
          shipments
        end
      end

      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count,
          per_page: collection.limit_value
        }
      end

      def authorize_trucker!
        render_error('Only truckers can perform this action', status: :forbidden) unless current_user.user_role == 'trucker'
      end

      def render_error(message, errors: [], status: :unprocessable_entity)
        render json: { success: false, message: message, errors: errors }, status: status
      end
    end
  end
end
