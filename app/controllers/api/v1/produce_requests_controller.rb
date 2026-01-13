# app/controllers/api/v1/produce_requests_controller.rb
module Api
  module V1
    class ProduceRequestsController < BaseController
      before_action :authenticate_user!
      before_action :set_produce_listing, only: [:new, :create]
      before_action :set_produce_request, only: [:show, :update, :destroy]

      # POST /produce_listings/:produce_listing_id/produce_requests
      def create
        @produce_request = @produce_listing.produce_requests.build(produce_request_params)
        @produce_request.market_profile = current_user.market_profile
        @produce_request.status = :pending

        if @produce_request.save
          NotificationService.notify_farmer_of_request(@produce_request)
          render json: { success: true, data: @produce_request }, status: :created
        else
          render json: { success: false, errors: @produce_request.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /produce_requests/:id
      def update
        # Farmer accepts/rejects request
        if current_user.farmer? && @produce_listing.farmer_profile == current_user.farmer_profile
          status = params[:produce_request][:status]

          if status.in?(%w[accepted declined])
            @produce_request.update!(status: status)

            if @produce_request.accepted?
              # ✅ Create shipment automatically
              shipment = Shipment.new(
                produce_request: @produce_request,
                produce_listing: @produce_request.produce_listing,
                origin_address: @produce_listing.farm_location['address'],
                destination_address: @produce_request.market_profile.location['address'],
                status: :pending
              )

              # Calculate distance
              if @produce_listing.latitude && @produce_request.market_profile.latitude
                shipment.distance_km = Geocoder::Calculations.distance_between(
                  [@produce_listing.latitude, @produce_listing.longitude],
                  [@produce_request.market_profile.latitude, @produce_request.market_profile.longitude]
                ).round(2)
              end

              # Calculate agreed price if trucker preselected (optional)
              shipment.agreed_price = shipment.calculate_shipping_cost(shipment.distance_km) if shipment.respond_to?(:calculate_shipping_cost)

              shipment.save!

              # Notify market and truckers
              NotificationService.notify_market_of_acceptance(@produce_request)
              NotificationService.notify_truckers_of_new_shipment(shipment)
            else
              NotificationService.notify_market_of_rejection(@produce_request)
            end

            render json: { success: true, message: "Request #{status}" }
          else
            render json: { success: false, message: 'Invalid status' }, status: :unprocessable_entity
          end
        else
          render json: { success: false, message: 'Unauthorized' }, status: :forbidden
        end
      end

      private

      def set_produce_listing
        @produce_listing = ProduceListing.find(params[:produce_listing_id])
      end

      def set_produce_request
        @produce_request = ProduceRequest.find(params[:id])
      end

      def produce_request_params
        params.require(:produce_request).permit(:quantity, :price_offered, :message)
      end
    end
  end
end
