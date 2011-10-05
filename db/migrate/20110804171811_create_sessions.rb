class CreateSessions < ActiveRecord::Migration
  def self.up
    create_table :sessions do |t|
      t.datetime :start_at
      t.datetime :end_at
      t.string   :description
      t.integer  :experiment_id
      t.boolean  :finished
      t.integer  :needed
      t.integer  :reserve
      t.integer  :location_id
      t.timestamps
    end
  end

  def self.down
    drop_table :sessions
  end
end
