# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token
  respond_to :json

  private

  def respond_with_BAK(current_user, _opts = {})
    render json: {
      status: { 
        code: 200, message: 'Logged in successfully.',
        data: { user: UserSerializer.new(current_user).serializable_hash[:data][:attributes] }
      }
    }, status: :ok
  end

  def respond_with(current_user, _opts = {})
    role = current_user.add_role :marketplace_user
    custom_jwt_payload = UserSerializer.new(current_user).serializable_hash[:data][:attributes]
    custom_jwt_payload["role"]  = "marketplace_user"
    custom_jwt_payload["categories"]  = ""
    custom_jwt_payload["socialhandles"]  = ""
    custom_jwt_payload["profile"]  = ""
    custom_jwt_payload["userscpa"]  = ""
    custom_jwt_payload["scope"]  = ""
    custom_jwt_payload["allocatedJobs"]  = ""
    custom_jwt_payload["total_cpa"]  = ""
    # custom_jwt_payload["iat"]  = ""
    # custom_jwt_payload["exp"]  = 0
    
    secret = Rails.application.credentials.devise_jwt_secret_key!
    render json: {
      # current_user: current_user,
      access_token: JWT.encode(custom_jwt_payload, secret)
    }, status: :ok
  end

  def respond_to_on_destroy
    if request.headers['Authorization'].present?
      jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, Rails.application.credentials.devise_jwt_secret_key!).first
      current_user = User.find(jwt_payload['sub'])
    end
    
    if current_user
      render json: {
        status: 200,
        message: 'Logged out successfully.'
      }, status: :ok
    else
      render json: {
        status: 401,
        message: "Couldn't find an active session."
      }, status: :unauthorized
    end
  end
end
