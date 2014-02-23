class ChangeIdeaStatusDefault < ActiveRecord::Migration
  def up
    change_column_default :ideas, :status, "published"
    change_column_null :ideas, :status, false
  end

  def down
    change_column_null :ideas, :status, true
    change_column_default :ideas, :status, nil
  end
end
