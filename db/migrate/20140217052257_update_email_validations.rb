class UpdateEmailValidations < ActiveRecord::Migration
  def up
    change_column :users, :email, :string,
      :null => false, :default => "", :limit => nil
  end

  def down
    change_column :users, :email, :string,
      :null => true, :default => nil, :limit => 100
  end
end
