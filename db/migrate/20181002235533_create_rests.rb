class CreateRests < ActiveRecord::Migration[5.2]
  def change
    create_table :rests do |t|
      t.integer :staff_id
      t.integer :group_id
      t.integer :wcp_train_flag
      t.float :working_hour
      t.date :day
      t.integer :rest_time
      t.datetime :rest_start
      t.timestamps
    end
  end
end
