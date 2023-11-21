class CreateUsersCpas < ActiveRecord::Migration[7.1]
  def change
    create_table :users_cpas do |t|
      t.integer "current_total_cpa", default: 0, null: false
      t.datetime "updated_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.string "userId", limit: 36
      t.index ["userId"], name: "FK_a904fb2854b42e8a4aac68faf7d"
    end
  end
end
