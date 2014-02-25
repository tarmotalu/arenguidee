class AddAuthorNameToIdea < ActiveRecord::Migration
  def change
    add_column :ideas, :author_name, :string, :null => false, :default => ""
  end
end
