class AddSlugToCategories < ActiveRecord::Migration
  def change
    add_column :categories, :slug, :string
    add_index :categories, :slug, unique: true
    Category.find_each(&:save)
    change_column :ideas, :name, :string, :length => 80
    change_column :points, :name, :string, :length => 80
  end
end
