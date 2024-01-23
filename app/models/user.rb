class User < ApplicationRecord
  rolify
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable, :recoverable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  after_create :assign_default_role

  def assign_default_role
    self.add_role(:admin) if self.roles.blank?
  end

  def self.calculateTotalCpa(id)
    usersCPA_details = UsersCpa.find_by(userId: id)
    usersCPA = usersCPA_details ? +usersCPA_details.current_total_cpa : 0
  end

  def reset_password!(password)
   self.reset_password_token = nil
   self.password = password
   save!
  end
end
