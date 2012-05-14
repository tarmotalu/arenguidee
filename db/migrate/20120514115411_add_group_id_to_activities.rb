class AddGroupIdToActivities < ActiveRecord::Migration
  def change
    add_column :activities, :group_id, :integer
    Activity.reset_column_information
    Activity.all.each do |a|
      a.save
    end
  end
end
