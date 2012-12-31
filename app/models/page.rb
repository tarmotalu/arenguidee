class Page < ActiveRecord::Base
  attr_accessible :body, :published, :slug, :standalone, :title
end
