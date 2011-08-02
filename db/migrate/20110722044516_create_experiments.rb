class CreateExperiments < ActiveRecord::Migration
  def self.up
    create_table :experiments do |t|
      t.string  :name
      t.string  :public_name
      t.string  :type
      t.string  :description
      t.string  :old_id
      
      t.timestamps
    end
  end

  def self.down
    drop_table :experiments
  end
end
