# This migration comes from taverna_lite (originally 20131129162622)
class CreateTavernaLiteFeatureModels < ActiveRecord::Migration
  def change
    create_table :taverna_lite_feature_models do |t|
      t.string :name

      t.timestamps
    end
  end
end
