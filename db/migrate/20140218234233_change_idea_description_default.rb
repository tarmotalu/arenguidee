class ChangeIdeaDescriptionDefault < ActiveRecord::Migration
  def up
    change_column_default :ideas, :description, ""
    change_column_null :ideas, :description, false
  end

  def down
    change_column_null :ideas, :description, true
    change_column_default :ideas, :description, nil
  end
end
