class Api::V1::DashboardController < ApplicationController
  skip_before_action :verify_authenticity_token
  EmpTypeList = ['Intern', 'Freelance', 'Part-Time', 'Full-Time']
  Monthly_Data = {
    "January": 0,
    "February": 0,
    "March": 0,
    "April": 0,
    "May": 0,
    "June": 0,
    "July": 0,
    "August": 0,
    "September": 0,
    "October": 0,
    "November": 0,
    "December": 0
  };

  ## this fn will return categorised list of total jobs, empType, recent jobs, job cetegory,location etc
  def fetchCategorisedData

    ## fetch params payload
    limit = params[:limit] || 25

    ## get the list of transactions
    jobs = Job.where("verified =?", "#{true}")

    ## get the total result count
    jobsCount =  Job.count

    ## concatenate location
    location = Job.where("verified =?", "#{true}").select("city, state")
    concatenatedLocation = location.map { |p| 
      ({
        label: "#{p['city']}, #{p['state']}",
        value: "#{p['city']}\u001F#{p['state']}",
      })
    }

    ## get categories with categories
    categories = getCategoriesAndJobCount()

    ## collect the jobTypes details
    jobTypes = getEmpTypeObj(EmpTypeList, limit)

    ## get the recent jobs
    recentJobs = getRecentJobs(limit)
    # recentJobs = Job.where("verified =?", "#{true}").limit(limit).order(updated_at: :desc)
    jobTypes["recentJobs"] = recentJobs
    
    ## return response
    render json: {jobsCount: jobsCount, location: concatenatedLocation, categories: categories, jobs: jobTypes}
  end

  ## this fn will return the number of records avaialble in both the tables (includes approved applicants count & verified jobs)
  def getCountForDashboard
    
    # check user is loggin or not; if not loggin return the error
    if !request.headers['Authorization']
      render_json('User Authorization token is required and can not be empty.', 400, 'msg') and return
    end
    jwt_payload = JWT.decode(request.headers['Authorization'].split(' ').last, Rails.application.credentials.devise_jwt_secret_key!).first
    current_user_id = jwt_payload['id'] || 0

    ## get parameters
    marketplace = params[:marketplace]
    if (marketplace && marketplace === "true")
      mothlyReferral = Applicant.find_by_sql "SELECT COUNT(*) as count, MONTHNAME(applicants.application_date) as month FROM `applicants`
        inner Join user_referral_codes as urc ON urc.referral_code = applicants.job_referal_code
        where urc.user_id = #{current_user_id}
        group By month"

      # generate monthwise data
      monthlyReferralData = genMonthWiseData(mothlyReferral)

      # mothlyCPA
      mothlyCPA = Applicant.find_by_sql "SELECT SUM(app.cpa) as count, DATE_FORMAT(app.application_date, '%M') as month FROM `user_referral_codes` 
      inner Join applicants as app ON user_referral_codes.referral_code = app.job_referal_code
      where user_referral_codes.user_id = #{current_user_id} AND app.shortlisted=true
      group By month"

      ## fetch total_CPA
      total_cpa = User.calculateTotalCpa(current_user_id)

      ## fetch genMonthWiseData
      monthlyCPAData = genMonthWiseData(mothlyCPA)
      render json: {mothlyReferral: monthlyReferralData, mothlyCPA: monthlyCPAData, total_cpa: total_cpa}
    else

      ## get totalJobs, verifiedJobs, notVerifiedJobs count
      jobsCount = Applicant.find_by_sql "SELECT COUNT(*) as totalJobs, 
        SUM(CASE WHEN verified = 1 THEN 1 ELSE 0 END) as verifiedJobs, 
        SUM(CASE WHEN verified = 0 THEN 1 ELSE 0 END) as notVerifiedJobs 
        FROM jobs"
      totalJobs = jobsCount.pluck(:totalJobs).join(',')
      verifiedJobs = jobsCount.pluck(:verifiedJobs).join(',')
      notVerifiedJobs = jobsCount.pluck(:notVerifiedJobs).join(',')

      ## get  totalApplicants, shortlistedApplicants, rejectedApplicants, pendingApplicants count
      applicantsCounts = Applicant.find_by_sql "SELECT COUNT(*) as totalApplicants, 
      SUM(CASE WHEN shortlisted = 1 THEN 1 ELSE 0 END) as shortlistedApplicants, 
      SUM(CASE WHEN shortlisted = 0 THEN 1 ELSE 0 END) as rejectedApplicants, 
      SUM(CASE WHEN shortlisted IS NULL THEN 1 ELSE 0 END) as pendingApplicants 
      FROM applicants"
      totalApplicants = applicantsCounts.pluck(:totalApplicants).join(',')
      shortlistedApplicants = applicantsCounts.pluck(:shortlistedApplicants).join(',')
      rejectedApplicants = applicantsCounts.pluck(:rejectedApplicants).join(',')
      pendingApplicants = applicantsCounts.pluck(:pendingApplicants).join(',')

      ## verifiedMonthlyJobs
      verifiedMonthlyJobs = getJobsCount("verified")

      ## totalMonthlyJobs
      totalMonthlyJobs = getJobsCount("total")

      ## total candidates count month wise
      totalMonthlyApplicants = getApplicantsShortlistedCount("total")

      ## shortlisted candidates count month wise
      shortlistedMonthlyData = getApplicantsShortlistedCount("shortlisted")

      ## rejected candidates count month wise
      rejecteddMonthlyData = getApplicantsShortlistedCount("rejected")

      ## return response
      render json: {
        jobs: {
            total: { count: +totalJobs, monthlyCount: totalMonthlyJobs },
            verified: { count: +verifiedJobs, monthlyCount: verifiedMonthlyJobs },
            notVerified: +notVerifiedJobs
        },
        applicants:
        {
            total: { count: +totalApplicants, monthlyCount: totalMonthlyApplicants },
            shortlisted: { count: +shortlistedApplicants, monthlyCount: shortlistedMonthlyData },
            rejected: { count: +rejectedApplicants, monthlyCount: rejecteddMonthlyData },
            pendingForReview: +pendingApplicants
        }
      }
    end

    
  end


  # dafault funcation to render content
  ## this way we can add multiple render funcation on the comtroller otherwise DoubleRenderError was triggered
  def render_json(data, status_code, main_key = 'data')
    render json: { "#{main_key}": data }, status: status_code
  end


  private
  ## supportive funcation that will return the jobs on the basis of their types
  def getEmpTypeObj(empTypeList, limit)
    empTypeObj = {}
    db_all_dataa = []
    empTypeList.each { |empType| 
        results = Job
        .joins("join categories ON categories.id = jobs.category_id")
        .joins("join companies ON companies.id = jobs.company_id")
        .select("Jobs.*,categories.id as cat_id,categories.title as cat_title,companies.*")
        .where("jobs.emp_type LIKE ? AND verified= ?","%#{empType}%", true)
        .limit(limit)
        .order(created_at: :desc)

        
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

        empTypeObj[empType] = db_all_data
    }
    
    ## return response
    return empTypeObj
    
  end

  ## supportive funcation that will return the jobs on the basis of their types
  def getEmpTypeObj_BAK(empTypeList, limit)
    empTypeObj = {}
    empTypeList.each { |empType| 
      empTypeCat = Job.where("emp_type LIKE ? AND verified= ?", "%#{empType}%", "#{true}").limit(limit).order(created_at: :desc)
      empTypeObj[empType] = empTypeCat
    }
    return empTypeObj
  end

  def getRecentJobs(limit)
    
    ## get the jobs data along with the category and companies
    limit = limit ? limit: 10
    results = Job
    .joins("join categories ON categories.id = jobs.category_id")
    .joins("join companies ON companies.id = jobs.company_id")
    .select("Jobs.*,categories.id as cat_id,categories.title as cat_title,companies.*")
    .where("jobs.verified = true")
    .limit(limit)
    .order(updated_at: :desc)

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

    ## return response
    return db_all_data
  end

  def getCategoriesAndJobCount()
    results = Category
    .joins("join jobs ON jobs.category_id = categories.id")
    .select("categories.id,categories.title as label, COUNT(jobs.category_id) as count")
    .where("jobs.verified = true")
    .group("jobs.category_id")

    db_all_data = []
    results.each do |item|
      tempHash = {}

      ## getting data from jobs table
      tempHash["id"] = item.id
      tempHash["label"] = item.label
      tempHash["count"] = item.count

      ##pushing this tempHash into the main array
      db_all_data.push(tempHash)
    end

    ## return response
    # puts db_all_data
    return db_all_data
  end

  ## generate monthwise data
  def genMonthWiseData(responseFromDB)
    monthlyData = Monthly_Data
    concatenatedLocation = responseFromDB.map { |p| 
      (
        monthlyData[p["month"]] = p["count"]
      )
    }
    # return response
    return monthlyData
  end

  ##  verified and unverified applicants count
  def getJobsCount(type)
    if (type === "total")
      monthlyData = Applicant.find_by_sql "SELECT COUNT(*) as count,  MONTHNAME(updated_at) as month 
      FROM jobs group By month"
      result = genMonthWiseData(monthlyData);
      return result 
    else
      monthlyData = Applicant.find_by_sql "SELECT Count(verified) as count,  MONTHNAME(updated_at) as month 
      FROM jobs where verified=true group By month"
      result = genMonthWiseData(monthlyData)
      return result
    end
  end

  ## shortlisted and rejected applicants count
  def getApplicantsShortlistedCount(type)
    if (type === "total")
      monthlyData = Applicant.find_by_sql "SELECT COUNT(*) as count,  MONTHNAME(application_date) as month 
      FROM applicants group By month"
      result = genMonthWiseData(monthlyData)
      return result
    else
      monthlyData = Applicant.find_by_sql "SELECT COUNT(shortlisted) as count,  MONTHNAME(application_date) as month 
      FROM applicants where shortlisted=true  group By month"
      result = genMonthWiseData(monthlyData)
      return result
    end
  end
end
