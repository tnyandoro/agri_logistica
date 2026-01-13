module Api
  module V1      
    class Api::V1::ProduceListingsController < ApplicationController
      before_action :authenticate_user!
      before_action :ensure_farmer!, except: [:index, :show]
      before_action :set_produce_listing, only: [:show, :edit, :update, :destroy]
      before_action :ensure_owner!, only: [:edit, :update, :destroy]

      def index
        @q = ProduceListing.available_now.includes(:farmer_profile).ransack(params[:q])
        @produce_listings = @q.result.page(params[:page]).per(12)
        @produce_types = ProduceListing.distinct.pluck(:produce_type).compact.sort
      end

      def show
        @produce_request = ProduceRequest.new if current_user&.market?
        @similar_listings = ProduceListing.available_now
                                        .where(produce_type: @produce_listing.produce_type)
                                        .where.not(id: @produce_listing.id)
                                        .limit(4)
      end

      def new
        @produce_listing = current_user.farmer_profile.produce_listings.build
      end

      def create
        @produce_listing = current_user.farmer_profile.produce_listings.build(produce_listing_params)

        if @produce_listing.save
          # Trigger matching job
          MatchNotificationJob.perform_later(@produce_listing.id)
          redirect_to @produce_listing, notice: 'Produce listing was successfully created.'
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @produce_listing.update(produce_listing_params)
          redirect_to @produce_listing, notice: 'Produce listing was successfully updated.'
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @produce_listing.destroy
        redirect_to produce_listings_url, notice: 'Produce listing was successfully deleted.'
      end

      private

      def set_produce_listing
        @produce_listing = ProduceListing.find(params[:id])
      end

      def ensure_farmer!
        redirect_to root_path, alert: 'Access denied.' unless current_user.farmer?
      end

      def ensure_owner!
        redirect_to root_path, alert: 'Access denied.' unless @produce_listing.farmer_profile == current_user.farmer_profile
      end

      def produce_listing_params
        params.require(:produce_listing).permit(
          :title, :description, :produce_type, :quantity, :unit, 
          :price_per_unit, :available_from, :available_until, :organic,
          quality_specs: {}
        )
      end
    end
  end
end
