# This migration comes from taverna_lite (originally 20140129141426)
class CreateTavernaLiteExampleTypes < ActiveRecord::Migration
  def change
    create_table :taverna_lite_example_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
