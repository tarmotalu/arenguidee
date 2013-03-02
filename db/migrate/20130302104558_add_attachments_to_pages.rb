class AddAttachmentsToPages < ActiveRecord::Migration
  def change
    add_column :pages, :attachment_file_name, :string
    add_column :pages, :attachment_file_size, :integer
    add_column :pages, :attachment_content_type, :string
    add_column :pages, :attachment_updated_at, :datetime
  end
end
