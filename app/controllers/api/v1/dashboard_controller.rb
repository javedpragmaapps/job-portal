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
    categories = Job.find_by_sql "SELECT categories.id as value, categories.title as label, 0 as count  from jobs left Join categories on jobs.category_id = categories.id where jobs.verified=true group By jobs.category_id"

    ## collect the jobTypes details
    jobTypes = getEmpTypeObj(EmpTypeList, limit)

    ## get the recent jobs
    recentJobs = Job.where("verified =?", "#{true}").limit(limit).order(updated_at: :desc)
    jobTypes["recentJobs"] = recentJobs
    
    ## return response
    render json: {jobsCount: jobsCount, location: concatenatedLocation, categories: categories, jobTypes: jobTypes}
  end

  ## this fn will return the number of records avaialble in both the tables (includes approved applicants count & verified jobs)
  def getCountForDashboard

    # check user is loggin or not; if not loggin return the error
    if !current_user
      render_json('User is not logging, Please login first.', 400, 'msg') and return
    end
    current_user_id = current_user.id || 0

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
    empTypeList.each { |empType| 
      empTypeCat = Job.where("emp_type LIKE ? AND verified= ?", "%#{empType}%", "#{true}").limit(limit).order(created_at: :desc)
      empTypeObj[empType] = empTypeCat
    }
    return empTypeObj
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
