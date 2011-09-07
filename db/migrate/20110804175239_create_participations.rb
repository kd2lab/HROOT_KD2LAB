class CreateParticipations < ActiveRecord::Migration
  def self.up
    create_table :participations do |t|
      t.integer :experiment_id
      t.integer :session_id
      t.integer :user_id
      t.boolean :invited
      t.boolean :registered
      t.boolean :showup
      t.boolean :participated

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
