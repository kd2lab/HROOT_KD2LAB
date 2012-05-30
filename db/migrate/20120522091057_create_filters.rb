class CreateFilters < ActiveRecord::Migration
  def change
    create_table :filters do |t|
      t.text :settings

      t.timestamps
    end
  end
end
