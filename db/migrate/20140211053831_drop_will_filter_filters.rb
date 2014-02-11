class DropWillFilterFilters < ActiveRecord::Migration
  def change
    drop_table :will_filter_filters
  end
end
