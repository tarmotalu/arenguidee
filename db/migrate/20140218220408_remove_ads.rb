class RemoveAds < ActiveRecord::Migration
  def up
    drop_table :ads
    drop_table :shown_ads
    remove_column :users, :ads_count
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
