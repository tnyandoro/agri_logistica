module Api
    module V1
      class Api::V1::ShipmentBidsController < BaseController
        before_action :set_shipment
        before_action :authorize_trucker, only: [:create]
  
        # POST /api/v1/shipments/:shipment_id/shipment_bids
        def create
          bid = @shipment.shipment_bids.build(bid_params)
          bid.trucking_company = current_user.trucking_company
          
          if bid.save
            render json: {
              success: true,
              message: 'Bid submitted successfully',
              data: ShipmentBidSerializer.new(bid).as_json
            }, status: :created
          else
            render_error('Failed to submit bid', errors: bid.errors.full_messages)
          end
        end
  
        # PATCH /api/v1/shipments/:shipment_id/shipment_bids/:id
        def update
          bid = @shipment.shipment_bids.find(params[:id])
          
          if bid.trucking_company == current_user.trucking_company
            if bid.update(bid_params)
              render json: {
                success: true,
                message: 'Bid updated successfully',
                data: ShipmentBidSerializer.new(bid).as_json
              }
            else
              render_error('Failed to update bid', errors: bid.errors.full_messages)
            end
          else
            render_error('Unauthorized', status: :forbidden)
          end
        end
  
        # DELETE /api/v1/shipments/:shipment_id/shipment_bids/:id
        def destroy
          bid = @shipment.shipment_bids.find(params[:id])
          
          if bid.trucking_company == current_user.trucking_company
            bid.destroy
            render json: {
              success: true,
              message: 'Bid withdrawn successfully'
            }
          else
            render_error('Unauthorized', status: :forbidden)
          end
        end
  
        private
  
        def set_shipment
          @shipment = Shipment.find(params[:shipment_id])
        end
  
        def authorize_trucker
          unless current_user.user_role == 'trucker'
            render_error('Only truckers can submit bids', status: :forbidden)
          end
        end
  
        def bid_params
          params.require(:shipment_bid).permit(
            :amount, :message, :estimated_delivery_time
          )
        end
      end
    end
  end