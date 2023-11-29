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

  ## This API will be use to update the applicant details
  def updateApplicant

    ## fetch  job_referal_code from the payload
    id = params[:id]
    applicantDetails = Applicant.where(id: id).update(JSON.parse(request.raw_post))
    render json: applicantDetails
  end

  ## This API will be use to delete the applicant
  def deleteApplicantById
    ## fetch  job_referal_code from the payload
    id = params[:id]
    applicantDetails = Applicant.find_by(id: id)
    if applicantDetails
      applicantDetails.destroy
      render json:  { error: "Applicant has been deleted."} 
    else
      render json: { error: "Applicant Not Found."} 
    end
  end


  ## This API will be use to mark a favorite job
  def markFavoriteJob

    ## fetch refNum & fav from the payload
    refNum = params[:refNum]
    fav = params[:fav]
    verified = true

    # check user is loggin or not; if not loggin return the error
    if !current_user
      render_json('User is not logging, Please login first.', 400, 'msg') and return
    end
    current_user_id = current_user.id || 0

    ## checked provided reference_number is exist on the JOb table or not
    ## if not exist return the error
    jobFoundList = Job.where("verified =? AND reference_number =?", "#{verified}", "#{refNum}")
    if jobFoundList.empty?
      render_json("Sorry, no jobs are available for the provided job reference number.: #{refNum}", 400, 'message') and return
    end

    ## check if UserFavJob exists or not, if not create it
    userFavJobExist = UserFavJob.where(referenceNumber: refNum).first_or_initialize(user_id: current_user_id)
    if (fav === "true")
      userFavJobExist.save
      render_json('Job marked as favorite successfully!', 400, 'message') and return
    elsif (userFavJobExist && fav === "false")
      userFavJobExist.destroy
      render_json('Job removed as favorite successfully!', 400, 'message') and return
    end
  end

  ## This API Fetch list of favorite jobs
  def listFavoriteJobs

    ## fetch parameters from the payload
    fav = params[:fav]
    refNum = params[:refNum]

    # check user is loggin or not; if not loggin return the error
    if !current_user
      render_json('User is not logging, Please login first.', 400, 'msg') and return
    end
    current_user_id = current_user.id || 0

    # # this statement partial copied from the source code
    # sql_statement  = "select * from jobs as j
    # inner join User_fav_jobs as ufj ON j.reference_number = ufj.referenceNumber
    # where ufj.user_id = #{current_user_id}"
    # results = ActiveRecord::Base.connection.execute(sql_statement)

    ## fetch the fav jobs results
    userFavJobDetails = UserFavJob.where("user_id =? AND referenceNumber =?", "#{current_user_id}", "#{refNum}")
    if userFavJobDetails.empty?
      render_json("Sorry, no fav jobs are available for the provided job reference number: #{refNum}", 400, 'message') and return
    else
      render json: userFavJobDetails, status:200
    end    
  end

  ## This API Fetch the referredjobs jobs details
  def referredjobs

    # check user is loggin or not; if not loggin return the error
    if !current_user
      render_json('User is not logging, Please login first.', 400, 'msg') and return
    end
    current_user_id = current_user.id || 0

    # sql_statement  = "select * from jobs as j
    # inner join User_fav_jobs as urc ON urc.job_reference_number = j.reference_number
    # where urc.user_id = #{current_user_id}"
    # results = ActiveRecord::Base.connection.exec_query(sql_statement)

    results = UserFavJob.find_by_sql "select j.* from jobs as j
    inner join user_referral_codes as urc ON urc.job_reference_number = j.reference_number
    where urc.user_id = #{current_user_id}"
  

    render json: results, status:200
  end

  ## This API Fetch the job categories details
  def jobCategories
    posts = Category.all();
    render json: posts, status:200 
  end

  # dafault funcation to render content
  ## this way we can add multiple render funcation on the comtroller otherwise DoubleRenderError was triggered
  def render_json(data, status_code, main_key = 'data')
    render json: { "#{main_key}": data }, status: status_code
  end
end
