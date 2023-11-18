class CreateApplicants < ActiveRecord::Migration[7.1]
  def change
    create_table :applicants do |t|
      t.integer "reference_number", null: false
      t.string "firstname", null: false
      t.string "lastname", null: false
      t.string "email", null: false
      t.string "mobile", null: false
      t.integer "age", null: false
      t.string "city", null: false
      t.string "gender", null: false
      t.string "address", null: false
      t.integer "experience", null: false
      t.string "max_qualification", null: false
      t.string "skills", null: false
      t.integer "current_salary", null: false
      t.integer "expected_salary", null: false
      t.integer "shortlisted", limit: 1
      t.string "job_referal_code", null: false
      t.string "languages", null: false
      t.integer "cpa", null: false
      t.string "job_source_platform", null: false
      t.string "file"
      t.string "profile_photo"
      t.datetime "application_date", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.json "education"
      t.string "about_me"
      t.json "employment_history"
      
    end
  end
end
