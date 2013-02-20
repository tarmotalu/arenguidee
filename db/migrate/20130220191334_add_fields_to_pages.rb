class AddFieldsToPages < ActiveRecord::Migration
  def change
    add_column :pages, :is_commentable, :boolean
    add_column :pages, :category_id, :integer
  end
end
