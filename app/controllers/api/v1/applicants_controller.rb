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
    if !request.headers['Authorization']
      render_json('User Authorization token is required and can not be empty.', 400, 'msg') and return
    end
    jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, Rails.application.credentials.devise_jwt_secret_key!).first
    current_user_id = jwt_payload['id'] || 0

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
    limit = params[:limit] || 20
    page = params[:page] ?(params[:page].to_i- 1) : 0
    offset = page.to_i * limit.to_i
    
    # check user is loggin or not; if not loggin return the error
    if !request.headers['Authorization']
      render_json('User Authorization token is required and can not be empty.', 400, 'msg') and return
    end
    jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, Rails.application.credentials.devise_jwt_secret_key!).first
    current_user_id = jwt_payload['id'] || 0

    results = Job.find_by_sql "SELECT j.*, cat.id as cat_id, cat.created_at as cat_created_at, cat.title as cat_title, com.* FROM jobs as j
        inner Join User_fav_jobs as ufj ON j.reference_number = ufj.referenceNumber
        left Join categories as cat ON j.category_id = cat.id
        left Join companies as com ON j.company_id = com.id
        where ufj.user_id = #{current_user_id}
        order by j.created_at DESC 
        LIMIT #{limit} OFFSET #{offset}
        "

    db_all_data = []
    results.each do |item|
      tempHash = {}

      ## getting data from jobs table
      tempHash["id"] = item.id
      tempHash["reference_number"] = item.reference_number
      tempHash["title"] = item.title
      tempHash["city"] = item.city
      tempHash["state"] = item.state
      tempHash["category_id"] = item.category_id
      tempHash["company_id"] = item.company_id
      tempHash["emp_type"] = [item.emp_type]
      tempHash["date"] = item.date
      tempHash["experience"] = item.experience
      tempHash["salary"] = item.salary
      tempHash["cpa"] = item.cpa
      tempHash["verified"] = item.verified
      tempHash["description"] = item.description
      tempHash["skills"] = item.skills
      tempHash["critical_resp"] = item.critical_resp
      tempHash["qualification"] = item.qualification
      tempHash["created_at"] = item.created_at
      tempHash["updated_at"] = item.updated_at
      tempHash["updated_by"] = item.updated_by
      tempHash["approved_by"] = item.approved_by
      tempHash["approved_at"] = item.approved_at
      tempHash["allocated_to"] = item.allocated_to

      ## getting data from category table
      tempHash["category"] = {
        id: item.cat_id, title: item.cat_title, created_at: item.created_at
      }

      ## getting data from company table
      tempHash["company"] = {
        id: item.cat_id, name: item.name, phone: item.phone, email: item.email, website: item.website, city: item.city,
        state: item.state, country: item.country, primary_industry: item.primary_industry, founded_in: item.founded_in,
        logo: item.logo, social_handles: item.social_handles, company_size: item.company_size, description: item.description,
        created_at: item.created_at,latitude: item.latitude,longitude: item.longitude
      }

      ##pushing this tempHash into the main array
      db_all_data.push(tempHash)
    end

    ## return response
    render json: {data: db_all_data, count: results.count}, status:200
  end

  ## This API Fetch the referredjobs jobs details
  def referredjobs
    
    # check user is loggin or not; if not loggin return the error
    if !request.headers['Authorization']
      render_json('User Authorization token is required and can not be empty.', 400, 'msg') and return
    end
    jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, Rails.application.credentials.devise_jwt_secret_key!).first
    current_user_id = jwt_payload['id'] || 0

    # sql_statement  = "select * from jobs as j
    # inner join User_fav_jobs as urc ON urc.job_reference_number = j.reference_number
    # where urc.user_id = #{current_user_id}"
    # results = ActiveRecord::Base.connection.exec_query(sql_statement)

    # results = UserFavJob.find_by_sql "select j.* from jobs as j
    # inner join user_referral_codes as urc ON urc.job_reference_number = j.reference_number
    # where urc.user_id = #{current_user_id}"


    results = Job
    .joins("inner join user_referral_codes as urc ON urc.job_reference_number = jobs.reference_number")
    .joins("join categories as cat ON cat.id = jobs.category_id")
    .joins("join companies as com ON com.id = jobs.company_id")
    .select("Jobs.*,cat.id as cat_id,cat.title as cat_title,com.*")

    db_all_data = []
    results.each do |item|
      tempHash = {}

      ## getting data from jobs table
      tempHash["id"] = item.id
      tempHash["reference_number"] = item.reference_number
      tempHash["title"] = item.title
      tempHash["city"] = item.city
      tempHash["state"] = item.state
      tempHash["category_id"] = item.category_id
      tempHash["company_id"] = item.company_id
      tempHash["emp_type"] = [item.emp_type]
      tempHash["date"] = item.date
      tempHash["experience"] = item.experience
      tempHash["salary"] = item.salary
      tempHash["cpa"] = item.cpa
      tempHash["verified"] = item.verified
      tempHash["description"] = item.description
      tempHash["skills"] = item.skills
      tempHash["critical_resp"] = item.critical_resp
      tempHash["qualification"] = item.qualification
      tempHash["created_at"] = item.created_at
      tempHash["updated_at"] = item.updated_at
      tempHash["updated_by"] = item.updated_by
      tempHash["approved_by"] = item.approved_by
      tempHash["approved_at"] = item.approved_at
      tempHash["allocated_to"] = item.allocated_to

      ## getting data from category table
      tempHash["category"] = {
        id: item.id, title: item.title, created_at: item.created_at
      }

      ## getting data from company table
      tempHash["company"] = {
        id: item.id, name: item.name, phone: item.phone, email: item.email, website: item.website, city: item.city,
        state: item.state, country: item.country, primary_industry: item.primary_industry, founded_in: item.founded_in,
        logo: item.logo, social_handles: item.social_handles, company_size: item.company_size, description: item.description,
        created_at: item.created_at,latitude: item.latitude,longitude: item.longitude
      }

      ##pushing this tempHash into the main array
      db_all_data.push(tempHash)
    end
  
    ##return reponse
    render json: {referredJobs: db_all_data}, status:200
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
