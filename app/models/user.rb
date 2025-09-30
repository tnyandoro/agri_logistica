class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Enum for roles with prefix to avoid conflicts
  # enum user_role: { farmer: 0, trucker: 1, market: 2 }, _prefix: true
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
  def full_name
    p = profile
    return email unless p

    p.respond_to?(:full_name) ? p.full_name :
      p.respond_to?(:company_name) ? p.company_name :
      p.respond_to?(:market_name) ? p.market_name : email
  end

  private

  # Automatically creates the associated profile after user creation
  def create_user_role_profile
    case user_role
    when 'farmer' then create_farmer_profile!
    when 'trucker' then create_trucking_company!
    when 'market' then create_market_profile!
    end
  rescue ActiveRecord::RecordInvalid
    # If creation fails, profile can be completed later
    nil
  end
end
