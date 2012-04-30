class Group < ActiveRecord::Base

  acts_as_set_sub_instance :table_name=>"groups"

  has_and_belongs_to_many :users

  def self.set_admin_for_group(group)

  end
end
