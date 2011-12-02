class CreateSessions < ActiveRecord::Migration
  def self.up
    create_table :sessions do |t|
      t.integer  :experiment_id
      t.integer  :location_id
      t.integer  :reference_session_id
      
      t.datetime :start_at
      t.datetime :end_at
      
      t.text     :description
      t.integer  :needed
      t.integer  :reserve
      
      t.integer :time_before
      t.integer :time_after
      
      t.timestamps
    end
    
    add_index :sessions, :experiment_id
    add_index :sessions, :reference_session_id
  end

  def self.down
    drop_table :sessions
  end
end
