class CreateJobAllocations < ActiveRecord::Migration[7.1]
  def change
    create_table :job_allocations do |t|
      t.string "allocated_to", null: false
      t.string "allocated_by", null: false
      t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.text "reference_number", null: false
      t.string "userId", limit: 36
      t.index ["allocated_to"], name: "IDX_24f6034f9654f6f1133b2db91f", unique: true
      t.index ["userId"], name: "REL_d7171ec5a4f40d22dd9337f55c", unique: true
    end
  end
end

