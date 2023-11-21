class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable, :recoverable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  def self.calculateTotalCpa(id)
    usersCPA_details = UsersCpa.find_by(userId: id)
    usersCPA = usersCPA_details ? +usersCPA_details.current_total_cpa : 0
  end
end
