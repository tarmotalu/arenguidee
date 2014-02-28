class ChangePagePublishedDefault < ActiveRecord::Migration
  def up
    change_column_default :pages, :published, true
    change_column_null :pages, :published, false
  end

  def down
    change_column_null :pages, :published, true
    change_column_default :pages, :published, nil
  end
end
