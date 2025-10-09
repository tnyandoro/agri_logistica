# frozen_string_literal: true
module Api
    module V1
      class BaseController < ActionController::API
        include ActionController::Cookies
        
        before_action :authenticate_api_user!
        before_action :check_profile_completion
        
        rescue_from ActiveRecord::RecordNotFound, with: :not_found
        rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
        rescue_from ActionController::ParameterMissing, with: :bad_request
        rescue_from JWT::DecodeError, with: :invalid_token
        rescue_from JWT::ExpiredSignature, with: :expired_token
  
        private
  
        def authenticate_api_user!
          token = extract_token
          
          if token.blank?
            render json: { error: 'No authorization token provided' }, status: :unauthorized
            return
          end
  
          begin
            decoded_token = decode_token(token)
            user_id = decoded_token[0]['user_id']
            @current_user = User.find(user_id)
          rescue ActiveRecord::RecordNotFound
            render json: { error: 'User not found' }, status: :unauthorized
          end
        end
  
        def current_user
          @current_user
        end
  
        def check_profile_completion
          return unless @current_user
          
          # Skip check for specific controllers/actions
          skip_controllers = ['profiles', 'dashboard']
          return if skip_controllers.include?(controller_name)
          
          unless @current_user.profile_complete?
            render json: { 
              error: 'Profile incomplete. Please complete your profile to continue.',
              profile_complete: false,
              user_role: @current_user.user_role,
              next_step: profile_completion_path
            }, status: :forbidden
          end
        end
  
        # Token helpers
        def extract_token
          # Support both "Bearer TOKEN" and just "TOKEN"
          auth_header = request.headers['Authorization']
          return nil if auth_header.blank?
          
          auth_header.start_with?('Bearer ') ? auth_header.split(' ').last : auth_header
        end
  
        def decode_token(token)
          JWT.decode(
            token,
            Rails.application.credentials.secret_key_base,
            true,
            { algorithm: 'HS256' }
          )
        end
  
        def encode_token(payload)
          # Token expires in 24 hours
          payload[:exp] = 24.hours.from_now.to_i
          JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
        end
  
        # Error handlers
        def not_found(exception)
          render json: { 
            error: 'Resource not found',
            message: exception.message 
          }, status: :not_found
        end
  
        def unprocessable_entity(exception)
          render json: { 
            error: 'Validation failed',
            message: exception.message,
            details: exception.record.errors.full_messages 
          }, status: :unprocessable_entity
        end
  
        def bad_request(exception)
          render json: { 
            error: 'Bad request',
            message: exception.message 
          }, status: :bad_request
        end
  
        def invalid_token(exception)
          render json: { 
            error: 'Invalid token',
            message: 'The provided authentication token is invalid' 
          }, status: :unauthorized
        end
  
        def expired_token(exception)
          render json: { 
            error: 'Token expired',
            message: 'Your session has expired. Please sign in again.' 
          }, status: :unauthorized
        end
  
        # Pagination helper
        def paginate(collection)
          page = params[:page] || 1
          per_page = [params[:per_page].to_i, 100].min || 20  # Max 100 per page
          
          paginated = collection.page(page).per(per_page)
          
          {
            data: paginated,
            meta: {
              current_page: paginated.current_page,
              next_page: paginated.next_page,
              prev_page: paginated.prev_page,
              total_pages: paginated.total_pages,
              total_count: paginated.total_count
            }
          }
        end
  
        # Response helpers
        def render_success(data, message: nil, status: :ok, meta: nil)
          response = { success: true, data: data }
          response[:message] = message if message
          response[:meta] = meta if meta
          render json: response, status: status
        end
  
        def render_error(message, status: :unprocessable_entity, errors: nil)
          response = { success: false, error: message }
          response[:errors] = errors if errors
          render json: response, status: status
        end
  
        def render_created(data, message: 'Resource created successfully')
          render_success(data, message: message, status: :created)
        end
  
        def render_updated(data, message: 'Resource updated successfully')
          render_success(data, message: message, status: :ok)
        end
  
        def render_deleted(message: 'Resource deleted successfully')
          render json: { success: true, message: message }, status: :ok
        end
  
        # Profile completion path helper
        def profile_completion_path
          case @current_user.user_role
          when 'farmer'
            '/api/v1/farmer_profiles/complete'
          when 'trucker'
            '/api/v1/trucking_companies/complete'
          when 'market'
            '/api/v1/market_profiles/complete'
          else
            '/api/v1/profile/complete'
          end
        end
      end
    end
  end