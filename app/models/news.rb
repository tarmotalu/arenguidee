class News < ActiveRecord::Base
  validates_presence_of :title
  validates_presence_of :url
  validates_presence_of :date
  # Let source remain optional.

  def initialize(attrs = {})
    super

    self.date ||= Date.current
  end
end
