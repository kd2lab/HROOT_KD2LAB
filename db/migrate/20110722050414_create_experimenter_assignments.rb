class CreateExperimenterAssignments < ActiveRecord::Migration
  def self.up
    create_table :experimenter_assignments do |t|
      t.integer :user_id
      t.integer :experiment_id
      t.timestamps
    end
  end

  def self.down
    drop_table :experimenter_assignments
  end
end
