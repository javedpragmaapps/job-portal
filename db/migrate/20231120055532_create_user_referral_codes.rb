class CreateUserReferralCodes < ActiveRecord::Migration[7.1]
  def change
    create_table :user_referral_codes do |t|
      t.string "user_id", null: false
      t.integer "job_reference_number", null: false
      t.string "referral_code", null: false
      t.integer "cpa", null: false
      t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    end
  end
end
