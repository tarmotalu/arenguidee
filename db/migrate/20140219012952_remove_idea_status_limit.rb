class RemoveIdeaStatusLimit < ActiveRecord::Migration
  def up
    change_column :ideas, :status, :string, :limit => nil
  end

  def down
    change_column :ideas, :status, :string, :limit => 50
  end
end
