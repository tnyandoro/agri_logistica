class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  enum role: { farmer: 0, trucker: 1, market: 2 }

  has_one :farmer_profile, dependent: :destroy
  has_one :trucking_company, dependent: :destroy
  has_one :market_profile, dependent: :destroy
  has_many :notifications, dependent: :destroy

  validates :phone, presence: true, uniqueness: true, format: { with: /\A[\+]?[0-9\-\s\(\)]+\z/, message: "Invalid phone format" }
  validates :role, presence: true

  after_create :create_role_profile

  def profile
    case role
    when 'farmer' then farmer_profile
    when 'trucker' then trucking_company
    when 'market' then market_profile
    end
  end

  def full_name
    profile&.respond_to?(:full_name) ? profile.full_name : profile&.company_name || profile&.market_name || email
  end

  private

  def create_role_profile
    case role
    when 'farmer'
      create_farmer_profile!
    when 'trucker'
      create_trucking_company!
    when 'market'
      create_market_profile!
    end
  rescue ActiveRecord::RecordInvalid
    # Profile will be completed later during registration flow
    nil
  end
end