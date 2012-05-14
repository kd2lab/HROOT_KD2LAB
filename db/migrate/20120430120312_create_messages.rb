class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.string :subject
      t.integer :recipient_id
      t.integer :sender_id
      t.integer :experiment_id
      t.text :message

      t.timestamps
    end
  end
end
