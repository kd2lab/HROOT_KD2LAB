class ChangeFilterTable < ActiveRecord::Migration
  def up
    rename_table :filters, :history_entries
    add_column :history_entries, :experiment_id, :integer
    add_column :history_entries, :action, :string
    add_column :history_entries, :user_count, :integer
    add_column :history_entries, :user_ids, :text
    rename_column :history_entries, :settings, :filter_settings
  end  
  
  def down
    remove_column :history_entries, :experiment_id
    remove_column :history_entries, :action
    remove_column :history_entries, :user_count
    remove_column :history_entries, :user_ids
    rename_column :history_entries, :filter_settings, :settings
    rename_table :history_entries, :filters
  end
end
