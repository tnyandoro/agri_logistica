module Api
  module V1
    class ProduceRequestsController < BaseController
      before_action :authenticate_user!
      before_action :ensure_market!, only: [:create, :new, :destroy]
      before_action :set_produce_listing
      before_action :set_produce_request, only: [:show, :update, :destroy]

      # GET /produce_listings/:produce_listing_id/produce_requests/:id
      def show
        if can_view_request?
          render json: @produce_request, status: :ok
        else
          render json: { error: 'Access denied.' }, status: :forbidden
        end
      end

      # POST /produce_listings/:produce_listing_id/produce_requests
      def create
        @produce_request = @produce_listing.produce_requests.build(produce_request_params)
        @produce_request.market_profile = current_user.market_profile
        @produce_request.status = :pending

        if @produce_request.save
          NotificationService.notify_farmer_of_request(@produce_request)
          render json: { produce_request: @produce_request, message: 'Request sent to farmer.' }, status: :created
        else
          render json: { errors: @produce_request.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /produce_listings/:produce_listing_id/produce_requests/:id
      def update
        if current_user.user_role_farmer? && @produce_listing.farmer_profile == current_user.farmer_profile
          handle_farmer_response
        elsif current_user.user_role_market? && @produce_request.market_profile == current_user.market_profile
          handle_market_update
        else
          render json: { error: 'Access denied.' }, status: :forbidden
        end
      end

      # DELETE /produce_listings/:produce_listing_id/produce_requests/:id
      def destroy
        if @produce_request.market_profile == current_user.market_profile && @produce_request.pending?
          @produce_request.destroy
          render json: { message: 'Request cancelled.' }, status: :ok
        else
          render json: { error: 'Cannot cancel this request.' }, status: :forbidden
        end
      end

      private

      def set_produce_listing
        @produce_listing = ProduceListing.find(params[:produce_listing_id])
      end

      def set_produce_request
        @produce_request = @produce_listing.produce_requests.find(params[:id])
      end

      def ensure_market!
        render json: { error: 'Access denied.' }, status: :forbidden unless current_user.user_role_market?
      end

      def can_view_request?
        return true if current_user.user_role_farmer? && @produce_listing.farmer_profile == current_user.farmer_profile
        return true if current_user.user_role_market? && @produce_request.market_profile == current_user.market_profile
        false
      end

      # Handle farmer accepting or declining a request
      def handle_farmer_response
        status = params[:status]
        unless status.in?(%w[accepted declined])
          return render json: { error: 'Invalid status' }, status: :unprocessable_entity
        end

        @produce_request.update!(status: status)

        if @produce_request.accepted?
          shipment = create_shipment_for_request(@produce_request)
          NotificationService.notify_market_of_acceptance(@produce_request)
          render json: { produce_request: @produce_request, shipment: shipment, message: 'Request accepted and shipment created.' }, status: :ok
        else
          NotificationService.notify_market_of_rejection(@produce_request)
          render json: { produce_request: @produce_request, message: 'Request declined.' }, status: :ok
        end
      end

      # Allow market to update their request before acceptance
      def handle_market_update
        if @produce_request.update(produce_request_params)
          render json: { produce_request: @produce_request, message: 'Request updated.' }, status: :ok
        else
          render json: { errors: @produce_request.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Create shipment for accepted produce request
      def create_shipment_for_request(produce_request)
        farmer_location = produce_request.produce_listing.farm_location
        market_location = produce_request.market_profile.location

        # Fallback to city if address is missing
        origin_address = farmer_location['address'] || farmer_location['city']
        destination_address = market_location['address'] || market_location['city']

        distance = Geocoder::Calculations.distance_between(
          [produce_request.produce_listing.latitude, produce_request.produce_listing.longitude],
          [produce_request.market_profile.latitude, produce_request.market_profile.longitude]
        ).round(2)

        agreed_price = produce_request.calculate_shipping_cost(distance)

        Shipment.create!(
          produce_listing: produce_request.produce_listing,
          produce_request: produce_request,
          origin_address: origin_address,
          destination_address: destination_address,
          distance_km: distance,
          agreed_price: agreed_price,
          status: :pending
        )
      end

      def produce_request_params
        params.require(:produce_request).permit(:quantity, :price_offered, :message)
      end
    end
  end
end
