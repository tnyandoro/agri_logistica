module Api
  module V1
    class Api::V1::ProduceRequestsController < BaseController
        before_action :authenticate_user!
        before_action :ensure_market!, except: [:show, :update]
        before_action :set_produce_listing
        before_action :set_produce_request, only: [:show, :edit, :update, :destroy]
      
        def show
          # Both market and farmer can view requests
          redirect_to root_path, alert: 'Access denied.' unless can_view_request?
        end
      
        def new
          @produce_request = @produce_listing.produce_requests.build
        end
      
        def create
          @produce_request = @produce_listing.produce_requests.build(produce_request_params)
          @produce_request.market_profile = current_user.market_profile
      
          if @produce_request.save
            # Notify farmer
            NotificationService.notify_farmer_of_request(@produce_request)
            redirect_to [@produce_listing, @produce_request], notice: 'Your request has been sent to the farmer.'
          else
            render :new, status: :unprocessable_entity
          end
        end
      
        def edit
          redirect_to root_path, alert: 'Access denied.' unless @produce_request.market_profile == current_user.market_profile
        end
      
        def update
          # Farmers can accept/reject, markets can update their requests
          if current_user.farmer? && @produce_listing.farmer_profile == current_user.farmer_profile
            handle_farmer_response
          elsif current_user.market? && @produce_request.market_profile == current_user.market_profile
            handle_market_update
          else
            redirect_to root_path, alert: 'Access denied.'
          end
        end
      
        def destroy
          if @produce_request.market_profile == current_user.market_profile && @produce_request.pending?
            @produce_request.destroy
            redirect_to @produce_listing, notice: 'Request cancelled.'
          else
            redirect_to root_path, alert: 'Cannot cancel this request.'
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
          redirect_to root_path, alert: 'Access denied.' unless current_user.market?
        end
      
        def can_view_request?
          return true if current_user.farmer? && @produce_listing.farmer_profile == current_user.farmer_profile
          return true if current_user.market? && @produce_request.market_profile == current_user.market_profile
          false
        end
      
        def handle_farmer_response
          status = params[:produce_request][:status]
          if status.in?(['accepted', 'rejected'])
            @produce_request.update!(status: status)
            
            if @produce_request.accepted?
              # Create shipment
              create_shipment_for_request
              NotificationService.notify_market_of_acceptance(@produce_request)
            else
              NotificationService.notify_market_of_rejection(@produce_request)
            end
            
            redirect_to dashboard_path, notice: "Request #{status}."
          else
            redirect_to [@produce_listing, @produce_request], alert: 'Invalid action.'
          end
        end
      
        def handle_market_update
          if @produce_request.update(produce_request_params)
            redirect_to [@produce_listing, @produce_request], notice: 'Request updated.'
          else
            render :edit, status: :unprocessable_entity
          end
        end
      
        def create_shipment_for_request
          Shipment.create!(
            produce_listing: @produce_listing,
            produce_request: @produce_request,
            origin_address: @produce_listing.farm_location['address'],
            destination_address: @produce_request.market_profile.location['address'],
            status: :pending_bids
          )
        end
      
        def produce_request_params
          params.require(:produce_request).permit(:quantity, :price_offered, :message)
        end
    end
  end
end