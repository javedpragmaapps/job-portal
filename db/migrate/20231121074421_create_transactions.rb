class CreateTransactions < ActiveRecord::Migration[7.1]
  def change
    create_table :transactions do |t|
      t.integer "redeemed_amount", null: false
      t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.string "idd", null: false
      t.string "user_id", null: false
      t.string "transaction_id", null: false
      t.integer "status", limit: 1
      t.string "approved_by"
      t.datetime "approved_at", precision: nil
      t.index ["user_id"], name: "FK_b4a3d92d5dde30f3ab5c34c5862"
    end
  end
end
