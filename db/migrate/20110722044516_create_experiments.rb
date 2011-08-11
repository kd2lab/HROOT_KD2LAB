class CreateExperiments < ActiveRecord::Migration
  def self.up
    create_table :experiments do |t|
      t.string  :name
      t.string  :typ
      t.string  :description
      t.boolean :restricted
      t.boolean :finished 
      t.boolean :hidden_stats
      t.boolean :hidden_calendar
      t.timestamps
    end
  end

  def self.down
    drop_table :experiments
  end
end
