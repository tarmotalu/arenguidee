class AddVideoUrlToIdeas < ActiveRecord::Migration
  def change
    add_column :ideas, :video_url, :string
  end
end
