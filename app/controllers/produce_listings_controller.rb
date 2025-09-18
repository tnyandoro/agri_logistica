class ProduceListingsController < ApplicationController
  before_action :set_produce_listing, only: %i[ show edit update destroy ]

  # GET /produce_listings or /produce_listings.json
  def index
    @produce_listings = ProduceListing.all
  end

  # GET /produce_listings/1 or /produce_listings/1.json
  def show
  end

  # GET /produce_listings/new
  def new
    @produce_listing = ProduceListing.new
  end

  # GET /produce_listings/1/edit
  def edit
  end

  # POST /produce_listings or /produce_listings.json
  def create
    @produce_listing = ProduceListing.new(produce_listing_params)

    respond_to do |format|
      if @produce_listing.save
        format.html { redirect_to @produce_listing, notice: "Produce listing was successfully created." }
        format.json { render :show, status: :created, location: @produce_listing }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @produce_listing.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /produce_listings/1 or /produce_listings/1.json
  def update
    respond_to do |format|
      if @produce_listing.update(produce_listing_params)
        format.html { redirect_to @produce_listing, notice: "Produce listing was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @produce_listing }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @produce_listing.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /produce_listings/1 or /produce_listings/1.json
  def destroy
    @produce_listing.destroy!

    respond_to do |format|
      format.html { redirect_to produce_listings_path, notice: "Produce listing was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_produce_listing
      @produce_listing = ProduceListing.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def produce_listing_params
      params.fetch(:produce_listing, {})
    end
end
