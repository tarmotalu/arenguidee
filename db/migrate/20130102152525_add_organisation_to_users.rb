class AddOrganisationToUsers < ActiveRecord::Migration
  def change
    add_column :users, :organisation, :string
    add_column :users, :title, :string
    add_column :users, :bio, :text
    add_column :users, :social_network_url, :string
  end
end
