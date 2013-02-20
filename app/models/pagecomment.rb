class Pagecomment < ActiveRecord::Base
  belongs_to :page
  belongs_to :user
  belongs_to :activity
  attr_accessible :content, :like_count
  validates_presence_of :user_id, :page_id
end
