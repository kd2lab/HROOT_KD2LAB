class CreateSessionGroups < ActiveRecord::Migration
  def change
    create_table :session_groups do |t|
      t.integer :signup_mode, :default => 1, :null => false
      t.integer :experiment_id
      t.timestamps
    end

    add_column :sessions, :session_group_id, :integer
  end
end
