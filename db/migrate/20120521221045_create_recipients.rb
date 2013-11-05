class CreateRecipients < ActiveRecord::Migration
  def change
    create_table :recipients do |t|
      t.integer :message_id
      t.integer :user_id
      t.datetime :sent_at
      t.timestamps
    end
  end
end
