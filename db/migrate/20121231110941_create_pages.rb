class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.string :slug
      t.string :title
      t.text :body
      t.boolean :published
      t.boolean :standalone

      t.timestamps
    end
  end
end
