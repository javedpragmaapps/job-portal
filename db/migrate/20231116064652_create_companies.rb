class CreateCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :companies do |t|
      t.string "name", null: false
      t.string "phone", null: false
      t.string "email", null: false
      t.string "website", null: false
      t.string "city"
      t.string "state"
      t.string "country"
      t.string "primary_industry", null: false
      t.integer "founded_in", null: false
      t.string "logo", null: false
      t.json "social_handles"
      t.integer "company_size", null: false
      t.string "description", limit: 1000
      t.timestamps
      t.decimal "latitude", precision: 9, scale: 6
      t.decimal "longitude", precision: 9, scale: 6

      t.index ["name"], name: "IDX_3dacbb3eb4f095e29372ff8e13", unique: true
    end
  end
end

