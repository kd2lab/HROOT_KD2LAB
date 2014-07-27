class ExpandFieldLengths < ActiveRecord::Migration
  def up
    change_column :history_entries, :user_ids, :text, limit: 4294967295
    change_column :locations, :description, :text, limit: 4294967295
  end

  def down
    change_column :history_entries, :user_ids, :text
    change_column :locations, :description, :string
  end
end
