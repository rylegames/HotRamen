class AddNewuserToUser < ActiveRecord::Migration[5.0]
  def change
    add_column :users, :newuser, :boolean
  end
end
