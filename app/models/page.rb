class Page < ActiveRecord::Base
  attr_accessible :body, :published, :slug, :standalone, :title, :category_id, :is_commentable, :attachment
  extend FriendlyId
  friendly_id :title, use: :slugged
  has_attached_file :attachment
  
  has_one :category
  belongs_to :category
  has_many :pagecomments
end
