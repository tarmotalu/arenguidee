class CreateNews < ActiveRecord::Migration
  def change
    create_table :news do |t|
      t.string :title, :null => false, :default => ""
      t.string :url, :null => false, :default => ""
      t.string :source, :null => false, :default => ""
      t.date :date, :null => false

      t.timestamps
    end
  end
end
