#encoding: utf-8

class CreateExperiments < ActiveRecord::Migration
  def self.up
    create_table :experiments do |t|
      t.string  :name
      t.text    :description
      t.text    :contact
      t.string  :sender_email
      t.boolean :finished 
      t.string  :auto_participation_key
      t.boolean :show_in_stats, :default => true
      t.boolean :show_in_calendar, :default => true
      t.integer :participations_count
      t.boolean :registration_active, :default => false
      
      t.string   :invitation_subject, :default => "Einladung zum Experiment"
      t.text     :invitation_text
      t.datetime :invitation_start
      t.integer  :invitation_size
      t.integer  :invitation_hours
      t.boolean  :invitation_prefer_new_users, :default => false
      
      t.boolean  :reminder_enabled, :default => false
      t.string   :reminder_subject
      t.text     :reminder_text
      t.integer  :reminder_hours, :default => 48
            
      t.string   :confirmation_subject, :default => "Anmeldebestätigung"
      t.text     :confirmation_text
      t.timestamps
    end
  end

  def self.down
    drop_table :experiments
  end
end
