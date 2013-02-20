class Page < ActiveRecord::Base
  attr_accessible :body, :published, :slug, :standalone, :title
  extend FriendlyId
  friendly_id :title, use: :slugged
  has_one :category
  belongs_to :category
  has_many :pagecomments
end
