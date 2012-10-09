class ChangeToLedermannSettings < ActiveRecord::Migration
  def up
    rename_column :settings, :thing_id, :target_id
    rename_column :settings, :thing_type, :target_type
  end

  def down
    rename_column :settings, :target_id, :thing_id
    rename_column :settings, :target_type, :thing_type
  end
end
