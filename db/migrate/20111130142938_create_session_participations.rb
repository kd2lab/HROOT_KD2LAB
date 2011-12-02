class CreateSessionParticipations < ActiveRecord::Migration
  def change
    create_table :session_participations do |t|
      t.integer :session_id
      t.integer :user_id

      t.boolean :showup, :null => false, :default => false
      t.boolean :participated, :null => false, :default => false
      t.boolean :noshow, :null => false, :default => false
      
      t.timestamps
    end
    
    add_index :session_participations, :user_id
    add_index :session_participations, :session_id
  end
end
