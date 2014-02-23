class AddTextToIdea < ActiveRecord::Migration
  def change
    add_column :ideas, :text, :text, :null => false, :default => ""
  end
end
