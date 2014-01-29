# This migration comes from taverna_lite (originally 20140109103309)
class AddWorkflowProfileIdToWorkflowPort < ActiveRecord::Migration
  def change
    add_column :taverna_lite_workflow_ports, :workflow_profile_id, :integer
  end
end
