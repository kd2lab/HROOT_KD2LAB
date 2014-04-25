class AddCanCreateExperimentField < ActiveRecord::Migration
  def change
    add_column :users, :can_create_experiment, :boolean, :default => false
  end
end