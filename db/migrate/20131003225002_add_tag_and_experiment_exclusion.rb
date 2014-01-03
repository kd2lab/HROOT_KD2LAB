class AddTagAndExperimentExclusion < ActiveRecord::Migration
  def up
    add_column :experiments, :exclude_tags, :text
    add_column :experiments, :exclude_experiments, :text
  end

  def down
  end
end