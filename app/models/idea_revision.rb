class IdeaRevision < ActiveRecord::Base
  class << self
    include HTMLDiff
  end
  scope :published, :conditions => "idea_revisions.status = 'published'"
  scope :by_recently_created, :order => "idea_revisions.created_at desc"  

  belongs_to :idea
  belongs_to :user
  belongs_to :category
    
  has_many :activities
  has_many :notifications, :as => :notifiable, :dependent => :destroy
      
  # this is actually just supposed to be 500, but bumping it to 520 because the javascript counter doesn't include carriage returns in the count, whereas this does.
  validates_length_of :description, :maximum => 300, :allow_blank => true, :allow_nil => true, :too_long => tr("has a maximum of 500 characters", "model/idea_revision")

  include Workflow
  workflow_column :status
  workflow do
    state :draft do
      event :publish, transitions_to: :published
    end
    state :archived do
      event :publish, transitions_to: :published
      event :remove, transitions_to: :removed
    end
    state :published do
      event :archive, transitions_to: :archived
      event :remove, transitions_to: :removed
    end
    state :removed do
      event :unremove, transitions_to: :published, meta: { validates_presence_of: [:published_at] }
      event :unremove, transitions_to: :archived
    end
  end

  before_save :truncate_user_agent
  
  def truncate_user_agent
    self.user_agent = self.user_agent[0..149] if self.user_agent # some user agents are longer than 150 chars!
  end
  
  def on_published_entry(new_state, event)
    self.published_at = Time.now
    self.auto_html_prepare
    begin
      Timeout::timeout(5) do   #times out after 5 seconds
        if idea.description
          self.description_diff = IdeaRevision.diff(idea.description, self.description).html_safe
        end
        if idea.name
          self.name_diff = IdeaRevision.diff(idea.name,self.name).html_safe
        end
      end
    rescue Timeout::Error
    end    
    idea.idea_revisions_count += 1    
    changed = false
    if idea.idea_revisions_count == 1
      ActivityIdeaNew.create(:user => user, :idea => idea, :idea_revision => self)
    else
      if idea.description != self.description
        changed = true
        ActivityIdeaRevisionDescription.create(:user => user, :idea => idea, :idea_revision => self)
      end
      if idea.name != self.name
        changed = true
        ActivityIdeaRevisionName.create(:user => user, :idea => idea, :idea_revision => self)
      end
      if idea.category != self.category
        changed = true
        ActivityIdeaRevisionCategory.create(:user => user, :idea => idea, :idea_revision => self)
      end
    end    
    if changed
      for a in idea.author_users
        if a.id != self.user_id
          notifications << NotificationIdeaRevision.new(:sender => self.user, :recipient => a)    
        end
      end
    end    
    idea.description = self.description
    idea.idea_revision_id = self.id
    idea.name = self.name
    idea.category = self.category
    idea.author_sentence = idea.author_user.login
    idea.author_sentence += ", #{tr("changes","model/revision")} " + idea.editors.collect{|a| a[0].login}.to_sentence if idea.editors.size > 0
    idea.published_at = Time.now
    idea.save(:validate => false)
    save(:validate => false)
    user.increment!(:idea_revisions_count)    
  end
  
  def on_archived_entry(new_state, event)
    self.published_at = nil
    save(:validate => false)
  end
  
  def on_removed_entry(new_state, event)
    idea.decrement!(:idea_revisions_count)
    user.decrement!(:idea_revisions_count)    
  end
  
  def is_up?
    value > 0
  end
  
  def is_down?
    value < 0
  end
  
  def is_neutral?
    value == 0
  end

  def idea_name
    idea.name if idea
  end
  
  def idea_name=(n)
    self.idea = Idea.find_by_name(n) unless n.blank?
  end
  
  def other_idea_name
    other_idea.name if other_idea
  end
  
  def other_idea_name=(n)
    self.other_idea = Idea.find_by_name(n) unless n.blank?
  end  
  
  def has_other_idea?
    attribute_present?("other_idea_id")
  end
  
  def text
    s = idea.name
    s += " [#{tr("In support", "model/revision")}]" if is_down?
    s += " [#{tr("Neutral", "model/revision")}]" if is_neutral?    
    s += "\r\n" + description
  end  
  
  def request=(request)
    if request
      self.ip_address = request.remote_ip
      self.user_agent = request.env['HTTP_USER_AGENT']
    else
      self.ip_address = "127.0.0.1"
      self.user_agent = "Import"
    end
  end
  
  def IdeaRevision.create_from_idea(idea,ip=nil,agent=nil)
    r = IdeaRevision.new
    r.idea = idea
    r.user = idea.user
    r.name = idea.name
    r.category = idea.category
    r.name_diff = idea.name
    r.description = idea.description
    r.description_diff = idea.description
    r.ip_address = ip ? ip : idea.ip_address
    r.user_agent = agent ? agent : idea.user_agent
    r.save(:validate => false)
    r.publish!
  end
  
  def url
    'http://' + idea.sub_instance.base_url_w_sub_instance + '/ideas/' + idea_id.to_s + '/idea_revisions/' + id.to_s + '?utm_source=ideas_changed&utm_medium=email'
  end  
  
  auto_html_for(:description) do
    html_escape
    youtube :width => 330, :height => 210
    vimeo :width => 330, :height => 180
    link :target => "_blank", :rel => "nofollow"
  end  
end
