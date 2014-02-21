class RemoveUsersLoginLimit < ActiveRecord::Migration
  def up
    change_column :users, :login, :string,
      :null => false, :default => "", :limit => nil
  end

  def down
    change_column :users, :login, :string,
      :null => false, :default => "", :limit => 40
  end
end
