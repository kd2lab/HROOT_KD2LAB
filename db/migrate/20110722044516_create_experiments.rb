class CreateExperiments < ActiveRecord::Migration
  def self.up
    create_table :experiments do |t|
      t.string  :name
      t.string  :typ
      t.string  :description
      t.boolean :restricted
      t.boolean :finished 
      t.boolean :show_in_stats, :default => true
      t.boolean :show_in_calendar, :default => true
      t.integer :experiment_participations_count
      t.timestamps
    end
  end

  def self.down
    drop_table :experiments
  end
end
