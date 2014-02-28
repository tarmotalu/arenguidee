class Page < ActiveRecord::Base
  extend FriendlyId
  friendly_id :title, :use => :slugged
  has_attached_file :attachment

  validates_presence_of :title
end
