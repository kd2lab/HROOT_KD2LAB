class CreateSessions < ActiveRecord::Migration
  def self.up
    create_table :sessions do |t|
      t.datetime :start
      t.string   :description
      t.integer  :duration
      t.integer  :experiment_id
      t.timestamps
    end
  end

  def self.down
    drop_table :sessions
  end
end
