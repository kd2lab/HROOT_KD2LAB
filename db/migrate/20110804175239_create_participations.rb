class CreateParticipations < ActiveRecord::Migration
  def self.up
    create_table :participations do |t|
      t.integer :experiment_id
      t.integer :session_id
      t.integer :user_id
      t.boolean :invited, :null => false, :default => false
      t.boolean :registered, :null => false, :default => false
      t.boolean :showup, :null => false, :default => false
      t.boolean :participated, :null => false, :default => false
      t.boolean :noshow, :null => false, :default => false
      
      t.timestamps
    end
    
    add_index :participations, :experiment_id
    add_index :participations, :user_id
    add_index :participations, :session_id
  end

  def self.down
    drop_table :participations
  end
end
