class DeviseCreateUsers < ActiveRecord::Migration
  def self.up
    create_table(:users) do |t|
      ## Database authenticatable
      t.string :email,              :null => false, :default => ""
      t.string :encrypted_password, :null => false, :default => ""

      ## Recoverable
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at
      
      ## Rememberable
      t.datetime :remember_created_at
      
      ## Trackable
      t.integer  :sign_in_count, :default => 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string   :current_sign_in_ip
      t.string   :last_sign_in_ip
      
      
      ## Confirmable
      t.string   :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at

      # user specific fields
      t.string :firstname
      t.string :lastname
      t.date :birthday
      t.string :matrikel
      t.string :role, :null => false, :default => "user"
      t.string :phone
      t.string :gender
      t.string :calendar_key
      t.boolean :deleted, :default => false
      t.integer :study_id
      t.integer :degree_id
      t.string :country_name
      t.integer :begin_month
      t.integer :begin_year
      t.integer :preference
      t.boolean :experience
      t.integer :noshow_count, :default => 0
      t.integer :participations_count, :default => 0
      
      t.integer :lang1
      t.integer :lang2
      t.integer :lang3
      t.integer :profession_id
      
      t.string   :secondary_email
      t.datetime :secondary_email_confirmed_at
      t.string   :secondary_email_confirmation_token

      #t.string   :change_email
      #t.string   :change_email_confirmation_token
      t.boolean :show_greeting, :default => true
      t.boolean :account_paused, :default => false
      
      t.boolean :imported, :default => false
      t.boolean :activated_after_import, :default => false
      t.string  :import_token
      t.string  :import_email
      t.string  :import_email_confirmation_token
      
      
      t.timestamps
    end

    add_index :users, :email,                :unique => true
    add_index :users, :reset_password_token, :unique => true
    add_index :users, :confirmation_token,   :unique => true
    add_index :users, :deleted
    add_index :users, :role
    
    
    # User.create(:email => "mail@ingmar.net", :password => "test", :password_confirmation => "test", :active => true, :firstname => "Ingmar", :lastname => "Baetge", :matrikel => "123")
    
    # add_index :users, :unlock_token,         :unique => true
    # add_index :users, :authentication_token, :unique => true
  end

  def self.down
    drop_table :users
  end
end
