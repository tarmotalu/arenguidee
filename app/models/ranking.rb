class Ranking < ActiveRecord::Base
  belongs_to :sub_instance
  belongs_to :idea
end
