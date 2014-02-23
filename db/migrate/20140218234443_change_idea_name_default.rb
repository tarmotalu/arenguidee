class ChangeIdeaNameDefault < ActiveRecord::Migration
  def up
    change_column_default :ideas, :name, ""
    change_column_null :ideas, :name, false
  end

  def down
    change_column_null :ideas, :name, true
    change_column_default :ideas, :name, nil
  end
end
