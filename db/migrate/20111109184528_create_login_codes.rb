class CreateLoginCodes < ActiveRecord::Migration
  def self.up
    create_table :login_codes do |t|
      t.integer :user_id
      t.string :code
      t.timestamps
    end
    
    add_index :login_codes, :user_id
  end

  def self.down
    drop_table :login_codes
  end
  
   
end
