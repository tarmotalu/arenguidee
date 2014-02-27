class ChangePointContentDefault < ActiveRecord::Migration
  def up
    change_column_default :points, :content, ""
    change_column_null :points, :content, false
  end

  def down
    change_column_null :points, :content, true
    change_column_default :points, :content, nil
  end
end
