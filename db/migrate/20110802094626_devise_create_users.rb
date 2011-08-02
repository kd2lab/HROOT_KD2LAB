class DeviseCreateUsers < ActiveRecord::Migration
  def self.up
    create_table(:users) do |t|
      t.database_authenticatable :null => false
      t.recoverable
      t.rememberable
      t.trackable
      t.confirmable

      # t.encryptable
      # t.lockable :lock_strategy => :failed_attempts, :unlock_strategy => :both
      # t.token_authenticatable

      # user specific fields
      t.string :firstname
      t.string :lastname
      t.string :matrikel
      t.string :old_id
      t.string :old_admin_name

      t.timestamps
    end

    add_index :users, :email,                :unique => true
    add_index :users, :reset_password_token, :unique => true
    add_index :users, :confirmation_token,   :unique => true
    
    
    # User.create(:email => "mail@ingmar.net", :password => "test", :password_confirmation => "test", :active => true, :firstname => "Ingmar", :lastname => "Baetge", :matrikel => "123")
    
    # add_index :users, :unlock_token,         :unique => true
    # add_index :users, :authentication_token, :unique => true
  end

  def self.down
    drop_table :users
  end
end
