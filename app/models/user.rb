# frozen_string_literal: true

class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Enum for roles with prefix to avoid conflicts
  enum :user_role, { farmer: 0, trucker: 1, market: 2 }, prefix: true

  # Associations
  has_one :farmer_profile, dependent: :destroy
  has_one :trucking_company, dependent: :destroy
  has_one :market_profile, dependent: :destroy
  has_many :notifications, dependent: :destroy

  # Validations
  validates :phone, presence: true, uniqueness: true,
                    format: { with: /\A[\+]?[0-9\-\s\(\)]+\z/, message: "Invalid phone format" }
  validates :user_role, presence: true

  # Callbacks
  after_create :create_user_role_profile

  # Returns the profile associated with the user's role
  def profile
    case user_role
    when 'farmer' then farmer_profile
    when 'trucker' then trucking_company
    when 'market' then market_profile
    else
      nil
    end
  end

  # Returns a display name depending on available profile fields
  def display_name
    p = profile
    return email unless p

    if p.respond_to?(:full_name) && p.full_name.present?
      p.full_name
    elsif p.respond_to?(:company_name) && p.company_name.present?
      p.company_name
    elsif p.respond_to?(:market_name) && p.market_name.present?
      p.market_name
    else
      email
    end
  end

  # Check if user has completed their profile
  def profile_complete?
    profile_obj = profile
    return false unless profile_obj

    case user_role
    when 'farmer'
      profile_obj.full_name.present? && 
      profile_obj.farm_name.present? && 
      profile_obj.farm_location.present?
    when 'trucker'
      profile_obj.company_name.present? && 
      profile_obj.vehicle_types.any?
    when 'market'
      profile_obj.market_name.present? && 
      profile_obj.location.present?
    else
      false
    end
  end

  private

  # Automatically creates the associated profile after user creation
  # This creates an empty profile that will be filled in later
  def create_user_role_profile
    case user_role
    when 'farmer' 
      create_farmer_profile!(
        full_name: '',
        farm_name: '',
        farm_location: {}
      )
    when 'trucker' 
      create_trucking_company!(
        company_name: ''
      )
    when 'market' 
      create_market_profile!(
        market_name: '',
        location: {}
      )
    end
  rescue ActiveRecord::RecordInvalid => e
    # Log the error but don't fail user creation
    Rails.logger.error "Failed to create profile for user #{id}: #{e.message}"
    nil
  end
end