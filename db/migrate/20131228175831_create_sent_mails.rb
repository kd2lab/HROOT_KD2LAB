class CreateSentMails < ActiveRecord::Migration
  def change
    create_table :sent_mails do |t|
      t.string :subject
      t.text :message
      t.string :from
      t.string :to
      t.integer :message_type
      t.integer :user_id
      t.integer :experiment_id
      t.integer :sender_id
      t.integer :session_id

      t.timestamps
    end

    add_index :sent_mails, :created_at
    add_index :sent_mails, :experiment_id
    
  end
end
