class ChangePageTitleAndBodyDefault < ActiveRecord::Migration
  def up
    change_column_default :pages, :title, ""
    change_column_default :pages, :body, ""
    change_column_null :pages, :title, false
    change_column_null :pages, :body, false
  end

  def down
    change_column_null :pages, :title, true
    change_column_null :pages, :body, true
    change_column_default :pages, :title, nil
    change_column_default :pages, :body, nil
  end
end
