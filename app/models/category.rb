class Category < ActiveRecord::Base
  has_many :ideas
  has_many :blog_posts
  has_many :activities, :order => "activities.created_at DESC, id DESC"
  belongs_to :page
  has_attached_file :icon, :styles => { :icon_32 => "32x32#", :icon_25 => "25x25#", :icon_40  => "40x40#", :icon_50  => "50x50#", :icon_100 => "100x100#" }

  validates_attachment_size :icon, :less_than => 5.megabytes
  validates_attachment_content_type :icon, :content_type => ['image/png']
  attr_accessible :blue_box_text, :name, :description, :page_id

  validates_presence_of :name

  acts_as_set_sub_instance :table_name=>"categories"
  extend FriendlyId
  friendly_id :name, use: :slugged

  def self.default_or_sub_instance
    if Category.count>0
      Category.all
    else
      Category.unscoped.where("sub_instance_id IS NULL").all
    end
  end

  def latest_activity
    activities.joins(:idea).where('activities.user_id is not null AND activities.type NOT LIKE "%Delete"').where("ideas.status = 'published'").first
  end

  def i18n_name
    tr(self.name, "model/category")
  end
  
  def to_url
    "/issues/#{id}-#{self.name.parameterize_full[0..60]}"
  end

  def show_url
    to_url
  end

  def idea_ids
    ideas.published.collect{|p| p.id}
  end

  def points_count
    Point.published.count(:conditions => ["idea_id in (?)",idea_ids])
  end

  def discussions_count
    Activity.active.discussions.for_all_users.by_recently_updated.count(:conditions => ["idea_id in (?)",idea_ids])
  end
  
  def self.for_sub_instance
    if SubInstance.current and Category.where(:sub_instance_id=>SubInstance.current.id).count > 0
      Category.where(:sub_instance_id=>SubInstance.current.id).order("name")
    else
      Category.where(:sub_instance_id=>nil).order("name")
    end
  end
end
