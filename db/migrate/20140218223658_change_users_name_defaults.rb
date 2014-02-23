class ChangeUsersNameDefaults < ActiveRecord::Migration
  def up
    change_column_default :users, :first_name, ""
    change_column_default :users, :last_name, ""
    change_column_null :users, :first_name, false
    change_column_null :users, :last_name, false
  end

  def down
    change_column_null :users, :first_name, true
    change_column_null :users, :last_name, true
    change_column_default :users, :first_name, nil
    change_column_default :users, :last_name, nil
  end
end
