#encoding: utf-8

class CreateSettings < ActiveRecord::Migration
  def self.up
    create_table :settings do |t|
      t.string :var, :null => false
      t.text   :value, :null => true
      t.integer :thing_id, :null => true
      t.string :thing_type, :limit => 30, :null => true
      t.timestamps
    end
    
    add_index :settings, [ :thing_type, :thing_id, :var ], :unique => true
    
    #Settings.experiment_classes = ['-', '3rd-Party-Punishment', 'Aktienmarkt', 'Alte', 'Auktionen', 'Bertrand', 'Budgetierung - Real Effort', 'Capital Budgeting - Antle/Eppen', 'Common Pool', 'Cournot', 'Diktator', 'Gift-exchange', 'Individ. (subjektives) Risiko', 'Individ. Intertemporalität', 'Individ. Unsicherheit', 'Investment', 'Koordination', 'LEN-Vertrag', 'Public Good', 'Signalspiel', 'Ultimatum', 'Verrechnungspreisverhandlung', 'Vertrauen', 'Werbemitteltest']
  end

  def self.down
    drop_table :settings
  end
end
