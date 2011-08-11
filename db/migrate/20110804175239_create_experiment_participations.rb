class CreateExperimentParticipations < ActiveRecord::Migration
  def self.up
    create_table :experiment_participations do |t|
      t.integer :experiment_id
      t.integer :session_id
      t.integer :user_id
      t.boolean :invited
      t.boolean :registered
      t.boolean :showup
      t.boolean :participated

      t.timestamps
    end
  end

  def self.down
    drop_table :experiment_participations
  end
end
