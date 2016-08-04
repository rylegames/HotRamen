class CreateEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :events do |t|
      t.string :title
      t.string :description
      t.datetime :begin_date
      t.datetime :end_date
      t.string :location
      t.float :latitude
      t.float :longitude

      t.timestamps
    end
  end
end
