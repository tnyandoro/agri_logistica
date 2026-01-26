module Api
  module V1
    class ProduceListingsController < BaseController
      before_action :authenticate_api_user!
      before_action :set_produce_listing, only: [:show, :update, :destroy]
      before_action :ensure_farmer!, only: [:create, :update, :destroy]
      before_action :ensure_owner!, only: [:update, :destroy]

      # GET /api/v1/produce_listings
      def index
        listings = ProduceListing
                     .available_now
                     .includes(:farmer_profile)
                     .order(created_at: :desc)

        render json: {
          data: listings.map { |l| serialize_listing(l) }
        }
      end

      # GET /api/v1/produce_listings/:id
      def show
        render json: {
          data: serialize_listing(@produce_listing),
          similar: ProduceListing
                     .available_now
                     .where(produce_type: @produce_listing.produce_type)
                     .where.not(id: @produce_listing.id)
                     .limit(4)
                     .map { |l| serialize_listing(l) }
        }
      end

      # POST /api/v1/produce_listings
      def create
        listing = current_user.farmer_profile.produce_listings.build(produce_listing_params)

        if listing.save
          MatchNotificationJob.perform_later(listing.id)

          render json: {
            message: "Produce listing created successfully",
            data: serialize_listing(listing)
          }, status: :created
        else
          render json: {
            error: "Validation failed",
            details: listing.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/produce_listings/:id
      def update
        if @produce_listing.update(produce_listing_params)
          render json: {
            message: "Produce listing updated successfully",
            data: serialize_listing(@produce_listing)
          }
        else
          render json: {
            error: "Validation failed",
            details: @produce_listing.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/produce_listings/:id
      def destroy
        @produce_listing.destroy
        render json: { message: "Produce listing deleted successfully" }
      end

      private

      def set_produce_listing
        @produce_listing = ProduceListing.find(params[:id])
      end

      def ensure_farmer!
        unless current_user.farmer?
          render json: { error: "Only farmers can perform this action" }, status: :forbidden
        end
      end

      def ensure_owner!
        unless @produce_listing.farmer_profile == current_user.farmer_profile
          render json: { error: "You do not own this listing" }, status: :forbidden
        end
      end

      def produce_listing_params
        params.require(:produce_listing).permit(
          :title,
          :description,
          :produce_type,
          :quantity,
          :unit,
          :price_per_unit,
          :available_from,
          :available_until,
          :organic,
          quality_specs: {}
        )
      end

      def serialize_listing(listing)
        {
          id: listing.id,
          title: listing.title,
          description: listing.description,
          produce_type: listing.produce_type,
          quantity: listing.quantity,
          unit: listing.unit,
          price_per_unit: listing.price_per_unit,
          available_from: listing.available_from,
          available_until: listing.available_until,
          organic: listing.organic,
          created_at: listing.created_at,
          farmer: {
            id: listing.farmer_profile.id,
            farm_name: listing.farmer_profile.farm_name,
            location: listing.farmer_profile.location
          }
        }
      end
    end
  end
end
