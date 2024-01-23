class Api::V1::UserController < ApplicationController
  skip_before_action :verify_authenticity_token
  def index
    posts = User.all();
    render json: posts, status:200
  end

  def show
    render json: { error: "Inside show Action"}
  end

  def create
    render json: { error: "Inside create Action"}
  end

  def update
    user = User.find(params[:id])
    if user.update(user_params)
      render json: { error: "the user info successfully updated"}
      # puts 'the user info successfully updated' #add whatever you want
    else
      render json: { error: "the user info failed "}
      # puts 'failed'
    end
  end

  def destroy
    render json: { error: "Inside destroy Action"}
  end

  def updateUserPassword
    
    # check user is loggin or not; if not loggin return the error
    if !request.headers['Authorization']
      render_json('User Authorization token is required and can not be empty.', 400, 'msg') and return
    end
    jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, Rails.application.credentials.devise_jwt_secret_key!).first
    current_user_id = jwt_payload['id'] || 0

    # find user by id
    newpass = params[:newpass]
    oldpass = params[:oldpass]
    if(newpass == oldpass)
      render_json('Old and New password are the same, Please use different password.', 400, 'msg') and return
    end
    # isUser = User.find(current_user_id)

    token = "Bearer eyJhbGciOiJIUzI1NiJ9.eyJmaXJzdG5hbWUiOiJhZG1pbiIsImxhc3RuYW1lIjoiYWRtaW4iLCJlbWFpbCI6InRlc3QxMUBnbWFpbC5jb20iLCJpZCI6MTEsImxvZ2dlZF9pbl9hdCI6bnVsbCwiY3JlYXRlZF9hdCI6IjIwMjQtMDEtMTUgMDU6MDc6MzggVVRDIiwiY2l0eSI6bnVsbCwic3RhdGUiOm51bGwsIm1vYmlsZSI6bnVsbCwiY3JlYXRlZF9kYXRlIjoiMDEvMTUvMjAyNCIsImxhc3RfbG9nZ2VkX2F0IjpudWxsLCJyb2xlIjoibWFya2V0cGxhY2VfdXNlciIsImNhdGVnb3JpZXMiOiIiLCJzb2NpYWxoYW5kbGVzIjoiIiwicHJvZmlsZSI6IiIsInVzZXJzY3BhIjoiIiwic2NvcGUiOiIiLCJhbGxvY2F0ZWRKb2JzIjoiIiwidG90YWxfY3BhIjoiIn0.47VHW_CaBxQILuNwWl2AznyA993p5rPTiwiZUAbiRrk"
    # isUser = User.find_by(reset_password_token: token)
    # user = JWT.decode(token.split(' ').last, Rails.application.credentials.devise_jwt_secret_key!).first
    user =  User.find(current_user_id)
    if user.present?
      if user.reset_password!(params[:newpass])
        render json: {status: "ok"}, status: :ok
      else
        render json: {error: user.errors.full_messages}, status: :unprocessable_entity
      end
    else
      render json: {error:  ["Link not valid or expired. Try generating a new link."]}, status: :not_found
    end
   


    # render json: isUser
  end

  def fetchReferralcode
    
    # check user is loggin or not; if not loggin return the error
    if !request.headers['Authorization']
      render_json('User Authorization token is required and can not be empty.', 400, 'msg') and return
    end
    jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, Rails.application.credentials.devise_jwt_secret_key!).first
    current_user_id = jwt_payload['id'] || 0

    ## fetch params payload
    jobRefNumber = params[:jobRefNumber]

    ## find job with reference number
    job = Job.find_by(reference_number: jobRefNumber)
    if !job
      render_json('Sorry, no jobs are available for the provided job reference number.', 400, 'msg') and return
    end

    # get cpa value and generate unique string
    cpa = job["cpa"]
    uniqueString1 = SecureRandom.base64(8)
    uniqueString2 = SecureRandom.base64(8)

    # create referral code return
    referralCode = "#{uniqueString1}-#{jobRefNumber}-#{uniqueString2}"


    ## create a records inside table
    objectWithReferral = {}
    objectWithReferral["user_id"] = current_user_id
    objectWithReferral["job_reference_number"] = jobRefNumber
    objectWithReferral["referral_code"] = referralCode
    objectWithReferral["cpa"] = cpa
    new_transaction_id = UserReferralCode.create(objectWithReferral)
    
    ## return the response
    render json: {referralCode: referralCode}
  end

  private
  # dafault funcation to render content
  ## this way we can add multiple render funcation on the comtroller otherwise DoubleRenderError was triggered
  def render_json(data, status_code, main_key = 'data')
    render json: { "#{main_key}": data }, status: status_code
  end

  def user_params
    params.require(:user).permit(:username, :email, :firstname, :lastname, :city, :state, :mobile, :socialhandles)
  end
end
