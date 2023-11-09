class AddDetailsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :firstname, :string
    add_column :users, :lastname, :string
    add_column :users, :logged_in_at, :datetime
    add_column :users, :categories, :text
    add_column :users, :socialhandles, :json
    add_column :users, :mobile, :string
    add_column :users, :city, :string
    add_column :users, :state, :string
    add_column :users, :jobAllocationsId, :integer

    add_index :users, :jobAllocationsId, unique: true
  end
end
