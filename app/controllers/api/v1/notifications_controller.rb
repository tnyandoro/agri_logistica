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