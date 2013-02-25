class AddHiddenToPagecomments < ActiveRecord::Migration
  def change
    add_column :pagecomments, :hidden, :boolean
  end
end
