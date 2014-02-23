class RemoveUsersNameLimits < ActiveRecord::Migration
  def up
    change_column :users, :first_name, :string,
      :null => false, :default => "", :limit => nil
    change_column :users, :last_name, :string,
      :null => false, :default => "", :limit => nil
  end

  def down
    change_column :users, :first_name, :string,
      :null => false, :default => "", :limit => 100
    change_column :users, :last_name, :string,
      :null => false, :default => "", :limit => 100
  end
end
