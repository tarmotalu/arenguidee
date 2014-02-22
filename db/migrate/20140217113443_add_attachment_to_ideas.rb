class AddAttachmentToIdeas < ActiveRecord::Migration
  def up
    add_attachment :ideas, :attachment
  end

  def down
    remove_attachment :ideas, :attachment
  end
end
