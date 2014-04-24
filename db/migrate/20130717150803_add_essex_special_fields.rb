class AddEssexSpecialFields< ActiveRecord::Migration
  def change
    add_column :users, :marital_status, :string, :default => ""
    add_column :users, :region, :string, :default => ""
    add_column :users, :ethnicity, :string, :default => ""
    add_column :users, :religion, :string, :default => ""
    add_column :users, :campaign, :string, :default => ""
  end
end
