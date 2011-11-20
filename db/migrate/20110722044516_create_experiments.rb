class CreateExperiments < ActiveRecord::Migration
  def self.up
    create_table :experiments do |t|
      t.string  :name
      t.text    :description
      t.text    :contact
      t.string  :sender_email
      t.boolean :registration_active, :default => false
      t.boolean :restricted
      t.boolean :finished 
      t.boolean :show_in_stats, :default => true
      t.boolean :show_in_calendar, :default => true
      t.integer :participations_count
      t.integer :experiment_type_id
      t.timestamps
    end
  end

  def self.down
    drop_table :experiments
  end
end
