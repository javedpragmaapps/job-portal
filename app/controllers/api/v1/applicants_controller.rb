class Api::V1::ApplicantsController < ApplicationController
  skip_before_action :verify_authenticity_token
  def index
  end

  def show
  end

  def create
  end

  def update
  end

  def destroy
  end

  def fetchAllApplicant
    query_params = request.query_parameters
    limit = query_params['limit'] || 5
    page = query_params['page'] || 1
    shortlisted = query_params['shortlisted']
    text = query_params['text']
    # render json: { error: limit} 


    ## filter result based on the parameteres
    whereObj = ""
    if (text && shortlisted)
      applicantDetails =  Applicant.where("firstname LIKE ? AND shortlisted LIKE ?", "%#{text}%", "%#{shortlisted}%").limit(limit).offset(page).order(id: :desc)
    elsif (text)
      applicantDetails =  Applicant.where("firstname LIKE ?", "%#{text}%").limit(limit).offset(page).order(id: :desc)
    elsif (shortlisted)
      applicantDetails =  Applicant.where("shortlisted = #{shortlisted}").limit(limit).offset(page).order(id: :desc)
    else
        applicantDetails =  Applicant.limit(limit).offset(page).order(id: :desc)
    end

    # check applicantDetails have data or not
    if !applicantDetails
      render_json('No applicants found matching your search criteria.', 400, 'msg') and return
    end
    

    # ## fetch total applicants available
    # applicantTotal =  Applicant.group(:shortlisted).count
    # puts "applicantTotal"
    # puts applicantTotal

    # check post is save or not
    if applicantDetails
      render json: applicantDetails, status:200
    end
  end

  ## This API will be use to save the applicant information
  def saveApplicant

    ## fetch  job_referal_code from the payload
    job_referal_code = params[:job_referal_code]
    email = params[:email]
    reference_number = params[:reference_number]

    ## check if job_referal_code exists in referral code table or not
    userReferralCodeDetails = UserReferralCode.find_by(referral_code: job_referal_code)
    if !userReferralCodeDetails
      render_json('Sorry, no jobs are available for the provided job referral code. Please double-check the job referral code and try again.', 400, 'msg') and return
    end

    ## fetch CPA details from userReferralCode table
    cpa = userReferralCodeDetails["cpa"]

    ## check email and reference_number are not already save into the database
    existingApplicant =  Applicant.where("email =? AND reference_number =?", "#{email}", "#{reference_number}")
    if !existingApplicant.empty?
      render_json('Your application for this job has already been submitted. Thank you for your interest!', 400, 'msg') and return
    end

    ## save it to the database
    applicantDetails = Applicant.create(JSON.parse(request.raw_post))
    render json: applicantDetails
  end

  # dafault funcation to render content
  ## this way we can add multiple render funcation on the comtroller otherwise DoubleRenderError was triggered
  def render_json(data, status_code, main_key = 'data')
    render json: { "#{main_key}": data }, status: status_code
  end
end
