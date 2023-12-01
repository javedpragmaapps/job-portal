class Api::V1::UserController < ApplicationController
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
    render json: { error: "Inside update Action"}
  end

  def destroy
    render json: { error: "Inside destroy Action"}
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
end
