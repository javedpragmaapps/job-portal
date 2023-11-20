class Api::V1::ApplicantsController < ApplicationController
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

  # dafault funcation to render content
  ## this way we can add multiple render funcation on the comtroller otherwise DoubleRenderError was triggered
  def render_json(data, status_code, main_key = 'data')
    render json: { "#{main_key}": data }, status: status_code
  end
end
