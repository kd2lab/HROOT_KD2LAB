class CreateSessionGroups < ActiveRecord::Migration
  def change
    create_table :session_groups do |t|
      t.integer :id
      t.integer :signup_mode

      t.timestamps
    end
  end
end
