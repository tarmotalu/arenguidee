class AddGroups < ActiveRecord::Migration
  def up
    create_table "groups", :force => true do |t|
      t.string  "name"
      t.text   "description"
      t.integer "sub_instance_id"
    end

    create_table "groups_users", :force => true, :id=>false do |t|
      t.integer  "user_id"
      t.integer "group_id"
      t.boolean "is_admin", :default=>false
    end

    add_column :ideas, :group_id, :integer, :default=>1

    g = Group.new
    g.name = "Public"
    g.save

    u=User.first
    Group.set_admin_for_group(u,g)
  end

  def down
  end
end
