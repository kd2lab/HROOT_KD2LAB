#encoding: utf-8
  
class AddSessionIdToMessage < ActiveRecord::Migration
  def self.up
    add_column :messages, :session_id, :integer
  end
  
  def self.down
    remove_column :messages, :session_id    
  end
  
end
