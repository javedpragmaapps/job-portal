class CreateUserFavJobs < ActiveRecord::Migration[7.1]
  def change
    create_table :user_fav_jobs do |t|
      t.string "user_id", null: false
      t.integer "referenceNumber", null: false
      t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
    end
  end
end
