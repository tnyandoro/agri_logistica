module Api
  module V1   1
    class ShipmentsController < BaseController
          before_action :set_shipment, only: [:show, :update, :destroy, :accept_bid, :complete, :cancel]
    
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
            shipments = Shipment.where(status: 'pending')
                                .order(pickup_date: :asc)
            
            paginated = paginate(shipments)
            
            render json: {
              success: true,
              data: paginated.map { |s| ShipmentSerializer.new(s, include_bids: true).as_json },
              pagination: pagination_meta(paginated)
            }
          end
    
          # GET /api/v1/shipments/my_shipments
          def my_shipments
            case current_user.user_role
            when 'farmer'
              shipments = current_user.farmer_profile.shipments
            when 'trucker'
              shipments = current_user.trucking_company.shipments
            else
              shipments = Shipment.none
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
            shipment = current_user.farmer_profile.shipments.build(shipment_params)
            
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
    
          # PATCH /api/v1/shipments/:id
          def update
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
    
          # PATCH /api/v1/shipments/:id/accept_bid
          def accept_bid
            bid = @shipment.shipment_bids.find(params[:bid_id])
            
            if @shipment.update(status: 'accepted', trucking_company: bid.trucking_company)
              bid.update(status: 'accepted')
              @shipment.shipment_bids.where.not(id: bid.id).update_all(status: 'rejected')
              
              render json: {
                success: true,
                message: 'Bid accepted successfully',
                data: ShipmentSerializer.new(@shipment.reload).as_json
              }
            else
              render_error('Failed to accept bid')
            end
          end
    
          # PATCH /api/v1/shipments/:id/complete
          def complete
            if @shipment.update(status: 'completed')
              render json: {
                success: true,
                message: 'Shipment marked as completed',
                data: ShipmentSerializer.new(@shipment).as_json
              }
            else
              render_error('Failed to complete shipment')
            end
          end
    
          # PATCH /api/v1/shipments/:id/cancel
          def cancel
            if @shipment.update(status: 'cancelled')
              render json: {
                success: true,
                message: 'Shipment cancelled',
                data: ShipmentSerializer.new(@shipment).as_json
              }
            else
              render_error('Failed to cancel shipment')
            end
          end
    
          # DELETE /api/v1/shipments/:id
          def destroy
            @shipment.destroy
            render json: {
              success: true,
              message: 'Shipment deleted successfully'
            }
          end
    
          private
    
          def set_shipment
            @shipment = Shipment.find(params[:id])
          end
    
          def shipment_params
            params.require(:shipment).permit(
              :pickup_location, :delivery_location, :pickup_date,
              :delivery_date, :cargo_type, :cargo_weight,
              :special_requirements, :budget, :produce_listing_id
            )
          end
    
          def filter_by_role(shipments)
            case current_user.user_role
            when 'farmer'
              shipments.where(farmer_profile: current_user.farmer_profile)
            when 'trucker'
              shipments.where(trucking_company: current_user.trucking_company)
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
        end
      end
    end
end
  
  # app/controllers/api/v1/shipment_bids_controller.rb
  module Api
    module V1
      class ShipmentBidsController < BaseController
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
  
  # app/controllers/api/v1/dashboard_controller.rb
  module Api
    module V1
      class DashboardController < BaseController
        # GET /api/v1/dashboard/stats
        def stats
          stats = case current_user.user_role
          when 'farmer'
            farmer_stats
          when 'trucker'
            trucker_stats
          when 'market'
            market_stats
          end
          
          render json: {
            success: true,
            data: stats
          }
        end
  
        # GET /api/v1/dashboard/recent_activity
        def recent_activity
          activities = []
          
          # Get recent notifications
          notifications = current_user.notifications
                                     .order(created_at: :desc)
                                     .limit(10)
          
          activities = notifications.map do |n|
            {
              type: 'notification',
              title: n.title,
              description: n.message,
              timestamp: n.created_at
            }
          end
          
          render json: {
            success: true,
            data: activities
          }
        end
  
        private
  
        def farmer_stats
          profile = current_user.farmer_profile
          {
            active_listings: profile.produce_listings.where(status: 'active').count,
            total_listings: profile.produce_listings.count,
            active_shipments: profile.shipments.where(status: ['pending', 'in_transit']).count,
            completed_shipments: profile.shipments.where(status: 'completed').count,
            total_revenue: calculate_farmer_revenue(profile)
          }
        end
  
        def trucker_stats
          company = current_user.trucking_company
          {
            active_shipments: company.shipments.where(status: 'in_transit').count,
            completed_shipments: company.shipments.where(status: 'completed').count,
            pending_bids: company.shipment_bids.where(status: 'pending').count,
            accepted_bids: company.shipment_bids.where(status: 'accepted').count,
            total_revenue: calculate_trucker_revenue(company)
          }
        end
  
        def market_stats
          profile = current_user.market_profile
          {
            active_orders: profile.produce_requests.where(status: 'pending').count,
            completed_orders: profile.produce_requests.where(status: 'completed').count,
            total_spent: calculate_market_spending(profile),
            favorite_suppliers: 3
          }
        end
  
        def calculate_farmer_revenue(profile)
          # Simplified calculation
          profile.produce_listings.where(status: 'sold')
                 .sum('quantity * price_per_unit')
        end
  
        def calculate_trucker_revenue(company)
          # Simplified calculation
          company.shipment_bids.where(status: 'accepted')
                 .sum(:amount)
        end
  
        def calculate_market_spending(profile)
          # Simplified calculation
          profile.produce_requests.where(status: 'completed')
                 .joins(:produce_listing)
                 .sum('produce_requests.quantity * produce_listings.price_per_unit')
        end
      end
    end
  end
  
  # app/controllers/api/v1/notifications_controller.rb
  module Api
    module V1
      class NotificationsController < BaseController
        # GET /api/v1/notifications
        def index
          notifications = current_user.notifications
                                     .order(created_at: :desc)
          
          paginated = paginate(notifications)
          
          render json: {
            success: true,
            data: paginated.map { |n| NotificationSerializer.new(n).as_json },
            pagination: pagination_meta(paginated),
            unread_count: current_user.notifications.where(read: false).count
          }
        end
  
        # GET /api/v1/notifications/:id
        def show
          notification = current_user.notifications.find(params[:id])
          notification.update(read: true)
          
          render json: {
            success: true,
            data: NotificationSerializer.new(notification).as_json
          }
        end
  
        # PATCH /api/v1/notifications/:id
        def update
          notification = current_user.notifications.find(params[:id])
          
          if notification.update(read: true)
            render json: {
              success: true,
              data: NotificationSerializer.new(notification).as_json
            }
          else
            render_error('Failed to update notification')
          end
        end
  
        # PATCH /api/v1/notifications/mark_all_read
        def mark_all_read
          current_user.notifications.where(read: false).update_all(read: true)
          
          render json: {
            success: true,
            message: 'All notifications marked as read'
          }
        end
  
        private
  
        def pagination_meta(collection)
          {
            current_page: collection.current_page,
            total_pages: collection.total_pages,
            total_count: collection.total_count,
            per_page: collection.limit_value
          }
        end
      end
    end
  end
