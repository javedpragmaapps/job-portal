class CreateCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :categories do |t|
      t.string "title", null: false
      t.datetime "created_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.index ["title"], name: "IDX_9f16dbbf263b0af0f03637fa7b", unique: true
    end
  end
end
