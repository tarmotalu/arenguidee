class AddWebsiteToIdea < ActiveRecord::Migration
  def change
    add_column :ideas, :website, :string
  end
end
