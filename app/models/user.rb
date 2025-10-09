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

  # IMPORTANT: Accept nested attributes for registration
  accepts_nested_attributes_for :farmer_profile, allow_destroy: true
  accepts_nested_attributes_for :trucking_company, allow_destroy: true
  accepts_nested_attributes_for :market_profile, allow_destroy: true

  # Validations
  validates :phone_number, presence: true, uniqueness: true,
                    format: { with: /\A[\+]?[0-9\-\s\(\)]+\z/, message: "Invalid phone format" }
  validates :user_role, presence: true

  # Commented out - now handled in registration controller for API
  # after_create :create_user_role_profile, unless: :has_profile?

  # Returns the profile associated with the user's role
  def profile
    case user_role&.to_sym
    when :farmer then farmer_profile
    when :trucker then trucking_company
    when :market then market_profile
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

    case user_role&.to_sym
    when :farmer
      profile_obj.full_name.present? && 
      profile_obj.farm_name.present? && 
      profile_obj.farm_location.present? &&
      profile_obj.farm_location.is_a?(Hash) &&
      !profile_obj.farm_location.dig('temp')
    when :trucker
      profile_obj.company_name.present? && 
      profile_obj.company_name != 'Temp Company' &&
      profile_obj.vehicle_types.any?
    when :market
      profile_obj.market_name.present? && 
      profile_obj.market_name != 'Temp Market' &&
      profile_obj.location.present? &&
      profile_obj.location.is_a?(Hash) &&
      !profile_obj.location.dig('temp')
    else
      false
    end
  end

  # Role name for display
  def role_name
    user_role&.to_s&.titleize
  end

  private

  # Check if profile was already created (via nested attributes)
  def has_profile?
    case user_role&.to_sym
    when :farmer
      farmer_profile.present?
    when :trucker
      trucking_company.present?
    when :market
      market_profile.present?
    else
      false
    end
  end
end