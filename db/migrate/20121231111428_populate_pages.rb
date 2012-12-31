class PopulatePages < ActiveRecord::Migration
  def up
    Page.create(:slug => 'footer', :title => 'footer', :body => 'insert footer HTML here', :published => true, :standalone => false)
    Page.create(:slug => 'mis-on-rahvakogu', :title => 'Mis on Rahvakogu?', :body => 'insert content HTML here', :published => true, :standalone => true)

  end

  def down
  end
end
