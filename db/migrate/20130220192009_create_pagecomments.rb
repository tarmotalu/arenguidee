class CreatePagecomments < ActiveRecord::Migration
  def change
    create_table :pagecomments do |t|
      t.references :page
      t.references :user
      t.integer :like_count
      t.text :content
      t.references :activity

      t.timestamps
    end
    add_index :pagecomments, :page_id
    add_index :pagecomments, :user_id
    add_index :pagecomments, :activity_id
  end
end
