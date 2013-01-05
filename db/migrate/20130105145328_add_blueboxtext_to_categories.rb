class AddBlueboxtextToCategories < ActiveRecord::Migration
  def change
    add_column :categories, :blue_box_text, :text
  end
end
