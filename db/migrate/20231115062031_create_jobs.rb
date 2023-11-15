class CreateJobs < ActiveRecord::Migration[7.1]
  def change
    create_table :jobs do |t|
      t.integer "reference_number", null: false
      t.string "title", null: false
      t.string "city", null: false
      t.string "state", null: false
      t.integer "category_id"
      t.integer "company_id"
      t.text "emp_type", null: false
      t.string "date", null: false
      t.json "experience", null: false
      t.json "salary", null: false
      t.integer "cpa", null: false
      t.integer "verified", limit: 1, default: 0, null: false
      t.string "description", limit: 1000, null: false
      t.string "skills", limit: 1000, null: false
      t.string "critical_resp", limit: 1000, null: false
      t.string "qualification", limit: 1000, null: false
      t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.string "updated_by"
      t.string "approved_by"
      t.datetime "approved_at", precision: nil
      t.string "allocated_to"
      
      t.index ["allocated_to"], name: "FK_fd15bc22008ce3fff7cbbdcf0e5"
      t.index ["category_id"], name: "FK_15f44c4b9fbb84e28a0346e930f"
      t.index ["company_id"], name: "FK_51cb12c924d3e8c7465cc8edff2"
      t.index ["reference_number"], name: "IDX_73eb63da5bd0fe1f83ab6fbe57", unique: true

      
    end
  end
end
