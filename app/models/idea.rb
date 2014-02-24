class Idea < ActiveRecord::Base
  include ActionView::Helpers::DateHelper
  self.per_page = 10
  has_attached_file :attachment

  validates_presence_of :category_id
  validates_presence_of :name
  validates_length_of :name, :maximum => 140
  validates_exclusion_of :description, :in => [nil]
  validates_length_of :description, :maximum => 500
  validates_exclusion_of :text, :in => [nil]
  validates_length_of :text, :maximum => 2500
  validates_inclusion_of :status, :in => %w[published pending removed]

  validates_format_of :website, :with => /(^$)|(^((http|https):\/\/)*[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix

  validates_attachment_size :attachment, {:in => 0..25.megabytes}
  allowed_types = [/^image\//, /^text\//] + %w[application/pdf]
  validates_attachment_content_type :attachment, :content_type => allowed_types

  after_create :on_published_entry

  scope :published, :conditions => "ideas.status = 'published'"
  scope :pending, :conditions => "ideas.status = 'pending'"

  scope :unpublished, :conditions => "ideas.status not in ('published','abusive')"

  scope :not_removed, :conditions => "ideas.status <> 'removed'"

  scope :flagged, :conditions => "flags_count > 0"

  scope :alphabetical, :order => "ideas.name asc"

  scope :top_rank, :order => "ideas.score desc, ideas.position asc"
  scope :top, :order => "ideas.score desc, ideas.position asc"
  scope :bottom, :order => "ideas.score asc, ideas.position desc"
  scope :top_three, :order => "ideas.score desc, ideas.position asc", :limit=>3

  scope :top_24hr, :conditions => "ideas.position_endorsed_24hr IS NOT NULL", :order => "ideas.position_endorsed_24hr asc"
  scope :top_7days, :conditions => "ideas.position_endorsed_7days IS NOT NULL", :order => "ideas.position_endorsed_7days asc"
  scope :top_30days, :conditions => "ideas.position_endorsed_30days IS NOT NULL", :order => "ideas.position_endorsed_30days asc"

  scope :not_top_rank, :conditions => "ideas.position > 25"
  scope :rising, :conditions => "ideas.trending_score > 0", :order => "ideas.trending_score desc"
  scope :falling, :conditions => "ideas.trending_score < 0", :order => "ideas.trending_score asc"
  scope :controversial, :conditions => "ideas.is_controversial = true", :order => "ideas.controversial_score desc"

  scope :rising_7days, :conditions => "ideas.position_7days_delta > 0"
  scope :flat_7days, :conditions => "ideas.position_7days_delta = 0"
  scope :falling_7days, :conditions => "ideas.position_7days_delta < 0"
  scope :rising_30days, :conditions => "ideas.position_30days_delta > 0"
  scope :flat_30days, :conditions => "ideas.position_30days_delta = 0"
  scope :falling_30days, :conditions => "ideas.position_30days_delta < 0"
  scope :rising_24hr, :conditions => "ideas.position_24hr_delta > 0"
  scope :flat_24hr, :conditions => "ideas.position_24hr_delta = 0"
  scope :falling_24hr, :conditions => "ideas.position_24hr_delta < 0"

  scope :finished, :conditions => "ideas.official_status in (-2,-1,2)"
  scope :revised, :conditions => "idea_revisions_count > 1"
  scope :by_recently_revised, :joins => :idea_revisions, :order => "idea_revisions.created_at DESC"
  scope :by_category, lambda {|cat| {:conditions => ["category_id=?",cat]}}
  scope :by_user_id, lambda{|user_id| {:conditions=>["user_id=?",user_id]}}
  scope :item_limit, lambda{|limit| {:limit=>limit}}
  scope :only_ids, :select => "ideas.id"

  scope :minu, :include => [:endorsements, :points]
  scope :alphabetical, :order => "ideas.name asc"
  scope :newest, :order => "ideas.published_at desc, ideas.created_at desc"
  scope :tagged, :conditions => "(ideas.cached_issue_list is not null and ideas.cached_issue_list <> '')"
  scope :untagged, :conditions => "(ideas.cached_issue_list is null or ideas.cached_issue_list = '')", :order => "ideas.endorsements_count desc, ideas.created_at desc"

  scope :by_most_recent_status_change, :order => "ideas.status_changed_at desc"

  adapter = Rails.configuration.database_configuration[Rails.env]["adapter"]
  scope :by_random, :order => adapter == "mysql2" ? "RAND()" : "RANDOM()"

  scope :item_limit, lambda{|limit| {:limit=>limit}}

  belongs_to :user
  belongs_to :sub_instance
  belongs_to :category
  belongs_to :idea_revision

  has_many :idea_revisions, :dependent => :destroy
  has_many :author_users, :through => :idea_revisions, :select => "distinct users.*", :source => :user, :class_name => "User"
  has_many :relationships, :dependent => :destroy
  has_many :incoming_relationships, :foreign_key => :other_idea_id, :class_name => "Relationship", :dependent => :destroy

  has_many :endorsements, :dependent => :destroy
  has_many :endorsers, :through => :endorsements, :conditions => "endorsements.status in ('active','inactive')", :source => :user, :class_name => "User"
  has_many :up_endorsers, :through => :endorsements, :conditions => "endorsements.status in ('active','inactive') and endorsements.value=1", :source => :user, :class_name => "User"
  has_many :down_endorsers, :through => :endorsements, :conditions => "endorsements.status in ('active','inactive') and endorsements.value=-1", :source => :user, :class_name => "User"

  has_many :points, :conditions => "points.status in ('published')"
  accepts_nested_attributes_for :points

  has_many :my_points, :conditions => "points.status in ('published')", :class_name => "Point"
  accepts_nested_attributes_for :my_points

  has_many :incoming_points, :foreign_key => "other_idea_id", :class_name => "Point"
  has_many :published_points, :conditions => "status = 'published'", :class_name => "Point", :order => "points.helpful_count-points.unhelpful_count desc"
  has_many :points_with_deleted, :class_name => "Point", :dependent => :destroy

  has_many :rankings, :dependent => :destroy
  has_many :activities, :dependent => :destroy

  has_many :charts, :class_name => "IdeaChart", :dependent => :destroy
  has_many :notifications, :as => :notifiable, :dependent => :destroy

  has_many :idea_status_change_logs, dependent: :destroy

  attr_accessor :idea_type

  acts_as_taggable_on :issues
  acts_as_list

  define_index do
    indexes name
    indexes description
    has category.name, :facet=>true, :as=>"category_name"
    has updated_at
    has sub_instance_id, :as=>:sub_instance_id, :type => :integer
    where "ideas.status in ('published','inactive')"
  end

  def category_name
    if category
      category.name
    else
      'No category'
    end
  end

  include Workflow
  workflow_column :status
  workflow do
    state :published do
      event :remove, transitions_to: :removed
    end

    state :pending do
      event :publish, transitions_to: :published
      event :remove, transitions_to: :removed
    end

    state :removed do
      event :bury, transitions_to: :buried
      event :unremove, transitions_to: :published, meta: { validates_presence_of: [:published_at] }
    end
  end

  # Workflow's write_initial_state interferes with validations.
  def write_initial_state; end

  def name=(name)
    super name.is_a?(String) ? name.strip : name
  end

  def to_param
    "#{id}-#{name.parameterize_full}"
  end

  def content
    self.name
  end

  def setup_revision
    IdeaRevision.create_from_idea(self)
  end

  def author
    user
  end

  def author_user
    self.author_users.order("idea_revisions.created_at ASC").first
  end

  def last_author
    self.author_users.order("idea_revisions.created_at DESC").last
  end

  def authors
    idea_revisions.map(&:user) #(:order => "count_all desc")
  end

  def editors
    idea_revisions.where("idea_revisions.user_id <> ?", user_id).map(&:user)
  end

  def all_for
    out = up_endorsers + points.published.up_value.map(&:user)
    return out.uniq
  end

  def all_against
    out = down_endorsers + points.published.down_value.map(&:user)
    return out.uniq
  end

  def endorse(user,request=nil,sub_instance=nil,referral=nil)
    return false if not user
    sub_instance = nil if sub_instance and sub_instance.id == 1 # don't log sub_instance if it's the default
    endorsement = self.endorsements.find_by_user_id(user.id)
    if not endorsement
      endorsement = Endorsement.new(:value => 1, :idea => self, :user => user, :sub_instance => sub_instance, :referral => referral)
      endorsement.ip_address = request.remote_ip if request
      endorsement.save
    elsif endorsement.is_down?
      endorsement.flip_up
      endorsement.save
    end

    if endorsement.replaced?
      endorsement.activate!
    end

    endorsement
  end

  def oppose(user,request=nil,sub_instance=nil,referral=nil)
    return false if not user
    sub_instance = nil if sub_instance and sub_instance.id == 1 # don't log sub_instance if it's the default
    endorsement = self.endorsements.find_by_user_id(user.id)
    if not endorsement
      endorsement = Endorsement.new(:value => -1, :idea => self, :user => user, :sub_instance => sub_instance, :referral => referral)
      endorsement.ip_address = request.remote_ip if request
      endorsement.save
    elsif endorsement.is_up?
      endorsement.flip_down
      endorsement.save
    end
    if endorsement.replaced?
      endorsement.activate!
    end
    return endorsement
  end

  def is_official_endorsed?
    official_value == 1
  end

  def is_official_opposed?
    official_value == -1
  end

  def is_rising?
    position_7days_delta > 0
  end

  def is_falling?
    position_7days_delta < 0
  end

  def up_endorsements_count
    Endorsement.where(:idea_id=>self.id, :value=>1).count
  end

  def down_endorsements_count
    Endorsement.where(:idea_id=>self.id, :value=>-1).count
  end

  def is_controversial?
    return false unless down_endorsements_count > 0 and up_endorsements_count > 0
    (up_endorsements_count/down_endorsements_count) > 0.5 and (up_endorsements_count/down_endorsements_count) < 2
  end

  def is_buried?
    status == tr("delisted", "model/idea")
  end

  def is_top?
    return false if position == 0
    position < Endorsement.max_position
  end

  def is_new?
    return true if not self.attribute_present?("created_at")
    created_at > Time.now-(86400*7) or position_7days == 0
  end

  def is_published?
    ['published','inactive'].include?(status)
  end
  alias :is_published :is_published?

  def is_finished?
    official_status > 1 or official_status < 0
  end

  def is_failed?
    official_status == -2
  end

  def is_successful?
    official_status == 2
  end

  def is_compromised?
    official_status == -1
  end

  def is_intheworks?
    official_status == 1
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

  def position_7days_delta_percent
    position_7days_delta.to_f/(position+position_7days_delta).to_f
  end

  def position_24hr_delta_percent
    position_24hr_delta.to_f/(position+position_24hr_delta).to_f
  end

  def position_30days_delta_percent
    position_30days_delta.to_f/(position+position_30days_delta).to_f
  end

  def value_name
    if is_failed?
      tr("Idea failed", "model/idea")
    elsif is_successful?
      tr("Idea succesful", "model/idea")
    elsif is_compromised?
      tr("Idea succesful with compromises", "model/idea")
    elsif is_intheworks?
      tr("Idea in the works", "model/idea")
    else
      tr("Idea has not been processed", "model/idea")
    end
  end

  def change_status!(change_status)
    if change_status == 0
      reactivate!
    elsif change_status == 2
      successful!
    elsif change_status == -2
      failed!
    elsif change_status == -1
      in_the_works!
    end
  end

  def reactivate!
    self.status_changed_at = Time.now
    self.official_status = 0
    self.status = 'published'
#    self.change = nil
    self.save(:validate => false)
#    deactivate_endorsements
  end

  def failed!
    ActivityIdeaOfficialStatusFailed.create(:idea => self)
    self.status_changed_at = Time.now
    self.official_status = -2
    self.status = 'inactive'
#    self.change = nil
    self.save(:validate => false)
    #deactivate_endorsements
  end

  def successful!
    ActivityIdeaOfficialStatusSuccessful.create(:idea => self)
    self.status_changed_at = Time.now
    self.official_status = 2
    self.status = 'inactive'
#    self.change = nil
    self.save(:validate => false)
    #deactivate_endorsements
  end

  def in_the_works!
    ActivityIdeaOfficialStatusInTheWorks.create(:idea => self)
    self.status_changed_at = Time.now
    self.official_status = -1
    self.status = 'inactive'
#    self.change = nil
    deactivate_ads_and_refund
    self.save(:validate => false)
    #deactivate_endorsements
  end

  def compromised!
    ActivityIdeaOfficialStatusCompromised.create(:idea => self)
    self.status_changed_at = Time.now
    self.official_status = -1
    self.status = 'inactive'
 #   self.change = nil
    self.save(:validate => false)
    #deactivate_endorsements
  end

  def deactivate_ads_and_refund
    self.ads.active.each do |ad|
      ad.finish!
      user = ad.user
      refund = ad.cost - ad.spent
      refund = 1 if refund > 0 and refund < 1
      refund = refund.abs.to_i
      if refund
        user.increment!(:capitals_count, refund)
        ActivityCapitalAdRefunded.create(:user => user, :idea => self, :capital => CapitalAdRefunded.create(:recipient => user, :amount => refund))
      end
    end
  end

  def is_editable?
    return true if official_status >= 0 && created_at.localtime >= Time.now-3600
  end

  def deactivate_endorsements
    for e in endorsements.active
      e.finish!
    end
  end

  def create_status_update(idea_status_change_log)
    return ActivityIdeaStatusUpdate.create(idea: self, idea_status_change_log: idea_status_change_log)
  end

  def reactivate!
    self.status = 'published'
    self.change = nil
    self.status_changed_at = Time.now
    self.official_status = 0
    self.save(:validate => false)
    for e in endorsements.active_and_inactive
      e.update_attribute(:status,'active')
      row = 0
      for ue in e.user.endorsements.active.by_position
        row += 1
        ue.update_attribute(:position,row) unless ue.position == row
        e.user.update_attribute(:top_endorsement_id,ue.id) if e.user.top_endorsement_id != ue.id and row == 1
      end
    end
  end

  def intheworks!
    ActivityIdeaOfficialStatusInTheWorks.create(:idea => self, :user => user)
    self.update_attribute(:status_changed_at, Time.now)
    self.update_attribute(:official_status, 1)
  end

  def official_status_name
    return tr("Failed", "status_messages") if official_status == -2
    return tr("In progress", "status_messages") if official_status == -1
    return tr("Unknown", "status_messages") if official_status == 0
    return tr("Published", "status_messages") if official_status == 1
    return tr("Successful", "status_messages") if official_status == 2
  end

  def has_change?
    attribute_present?("change_id") and self.status != 'inactive' and change and not change.is_expired?
  end

  def has_tags?
    attribute_present?("cached_issue_list")
  end

  def replaced?
    attribute_present?("change_id") and self.status == 'inactive'
  end

  def up_endorser_ids
    @up_endorser_ids ||= endorsements.active_and_inactive.endorsing.collect{|e|e.user_id.to_i}.uniq.compact
  end
  def down_endorser_ids
    @down_endorser_ids ||= endorsements.active_and_inactive.opposing.collect{|e|e.user_id.to_i}.uniq.compact
  end
  def endorser_ids
    @endoreser_ids ||= endorsements.active_and_inactive.collect{|e|e.user_id.to_i}.uniq.compact
  end
  def all_idea_ids_in_same_tags
    all_idea_ids_in_same_tags ||= begin
      ts = Tagging.find(:all, :conditions => ["tag_id in (?) and taggable_type = 'Idea'",taggings.collect{|t|t.tag_id}.uniq.compact])
      ts.collect{|t|t.taggable_id}.uniq.compact
    end
  end

  def undecideds
    return [] unless has_tags? and endorsements_count > 2
    @undecideds ||= begin
      User.find_by_sql("
      select distinct users.*
      from users, endorsements
      where endorsements.user_id = users.id
      and endorsements.status = 'active'
      and endorsements.idea_id in (#{all_idea_ids_in_same_tags.join(',')})
      and endorsements.user_id not in (#{endorser_ids.join(',')})
      ")
    end
  end

  def related(limit=10)
    Idea.find_by_sql(["SELECT ideas.*, count(*) as num_tags
    from taggings t1, taggings t2, ideas
    where
    t1.taggable_type = 'Idea' and t1.taggable_id = ?
    and t1.tag_id = t2.tag_id
    and t2.taggable_type = 'Idea' and t2.taggable_id = ideas.id
    and t2.taggable_id <> ?
    and ideas.status = 'published'
    group by ideas.id
    order by num_tags desc, ideas.endorsements_count desc
    limit ?",id,id,limit])
  end

  def merge_into(p2_id,preserve=false,flip=0) #pass in the id of the idea to merge this one into.
    p2 = Idea.find(p2_id) # p2 is the idea that this one will be merged into
    for e in endorsements
      if not exists = p2.endorsements.find_by_user_id(e.user_id)
        e.idea_id = p2.id
        if flip == 1
          if e.value < 0
            e.value = 1
          else
            e.value = -1
          end
        end
        e.save(:validate => false)
      end
    end
    p2.reload
    size = p2.endorsements.active_and_inactive.length
    up_size = p2.endorsements.active_and_inactive.endorsing.length
    down_size = p2.endorsements.active_and_inactive.opposing.length
    Idea.update(p2.id, endorsements_count: size, up_endorsements_count: up_size, down_endorsements_count: down_size)

    # look for the activities that should be removed entirely
    for a in Activity.find(:all, :conditions => ["idea_id = ? and type in ('ActivityIdeaDebut','ActivityIdeaNew','ActivityIdeaRenamed','ActivityIdeaFlag','ActivityIdeaFlagInappropriate','ActivityIdeaOfficialStatusCompromised','ActivityIdeaOfficialStatusFailed','ActivityIdeaOfficialStatusIntheworks','ActivityIdeaOfficialStatusSuccessful','ActivityIdeaRising1','ActivityIssueIdea1','ActivityIssueIdeaControversial1','ActivityIssueIdeaOfficial1','ActivityIssueIdeaRising1')",self.id])
      a.destroy
    end
    #loop through the rest of the activities and move them over
    for a in activities
      if flip == 1
        for c in a.comments
          if c.is_opposer?
            c.is_opposer = false
            c.is_endorser = true
            c.save(:validate => false)
          elsif c.is_endorser?
            c.is_opposer = true
            c.is_endorser = false
            c.save(:validate => false)
          end
        end
        if a.class == ActivityEndorsementNew
          a.update_attribute(:type,'ActivityOppositionNew')
        elsif a.class == ActivityOppositionNew
          a.update_attribute(:type,'ActivityEndorsementNew')
        elsif a.class == ActivityEndorsementDelete
          a.update_attribute(:type,'ActivityOppositionDelete')
        elsif a.class == ActivityOppositionDelete
          a.update_attribute(:type,'ActivityEndorsementDelete')
        elsif a.class == ActivityEndorsementReplaced
          a.update_attribute(:type,'ActivityOppositionReplaced')
        elsif a.class == ActivityOppositionReplaced
          a.update_attribute(:type,'ActivityEndorsementReplaced')
        elsif a.class == ActivityEndorsementReplacedImplicit
          a.update_attribute(:type,'ActivityOppositionReplacedImplicit')
        elsif a.class == ActivityOppositionReplacedImplicit
          a.update_attribute(:type,'ActivityEndorsementReplacedImplicit')
        elsif a.class == ActivityEndorsementFlipped
          a.update_attribute(:type,'ActivityOppositionFlipped')
        elsif a.class == ActivityOppositionFlipped
          a.update_attribute(:type,'ActivityEndorsementFlipped')
        elsif a.class == ActivityEndorsementFlippedImplicit
          a.update_attribute(:type,'ActivityOppositionFlippedImplicit')
        elsif a.class == ActivityOppositionFlippedImplicit
          a.update_attribute(:type,'ActivityEndorsementFlippedImplicit')
        end
      end
      if preserve and (a.class.to_s[0..26] == 'ActivityIdeaAcquisition' or a.class.to_s[0..25] == 'ActivityCapitalAcquisition')
      else
        a.update_attribute(:idea_id,p2.id)
      end
    end
    for a in ads
      a.update_attribute(:idea_id,p2.id)
    end
    for point in points_with_deleted
      point.idea = p2
      if flip == 1
        if point.value > 0
          point.value = -1
        elsif point.value < 0
          point.value = 1
        end
        # need to flip the helpful/unhelpful counts
        helpful = point.endorser_helpful_count
        unhelpful = point.endorser_unhelpful_count
        point.endorser_helpful_count = point.opposer_helpful_count
        point.endorser_unhelpful_count = point.opposer_unhelpful_count
        point.opposer_helpful_count = helpful
        point.opposer_unhelpful_count = unhelpful
      end
      point.save(:validate => false)
    end
    for point in incoming_points
      if flip == 1
        point.other_idea = nil
      elsif point.other_idea == p2
        point.other_idea = nil
      else
        point.other_idea = p2
      end
      point.save(:validate => false)
    end
    if not preserve # set preserve to true if you want to leave the Change and the original idea in tact, otherwise they will be deleted
      for c in changes_with_deleted
        c.destroy
      end
    end
    # find any issues they may be the top prioritiy for, and remove
    for tag in Tag.find(:all, :conditions => ["top_idea_id = ?",self.id])
      tag.update_attribute(:top_idea_id,nil)
    end
    # zap all old rankings for this idea
    Ranking.connection.execute("delete from rankings where idea_id = #{self.id.to_s}")
    self.reload
    self.destroy if not preserve
    return p2
  end

  def flip_into(p2_id,preserve=false) #pass in the id of the idea to flip this one into.  it'll turn up endorsements into down endorsements and vice versa
    merge_into(p2_id,1)
  end


  def show_url
    '/ideas/' + to_param
    # if self.sub_instance_id
    #   Instance.current.homepage_url(self.sub_instance) + 'ideas/' + to_param
    # else
    #   Instance.current.homepage_url + 'ideas/' + to_param
    # end
  end

  def new_point_url(args = {})
    supp = args.has_key?(:support) ? "?support=#{args[:support]}" : ""
    if self.sub_instance_id
      self.sub_instance.url('ideas/' + to_param + '/points/new' + supp)
    else
      Instance.current.homepage_url + 'ideas/' + to_param
    end
  end

  def show_discussion_url
    show_url + '/discussions'
  end

  def show_top_points_url
    show_url + '/top_points'
  end

  def show_endorsers_url
    show_url + '/endorsers'
  end

  def show_opposers_url
    show_url + '/opposers'
  end

  # this uses http://is.gd
  def create_short_url
    self.short_url = open('http://is.gd/create.php?longurl=' + show_url, "UserAgent" => "Ruby-ShortLinkCreator").read[/http:\/\/is\.gd\/\w+(?=" onselect)/]
  end

  def latest_idea_process_at
    latest_idea_process_txt = Rails.cache.read("latest_idea_process_at_#{self.id}")
    unless latest_idea_process_txt
      idea_process = IdeaProcess.find_by_idea_id(self, :order=>"created_at DESC, stage_sequence_number DESC")
      if idea_process
        time = idea_process.last_changed_at
      else
        time = Time.now-5.years
      end
      if idea_process.stage_sequence_number == 1 and idea_process.process_discussions.count == 0
        stage_txt = "#{tr("Waiting for discussion","althingi_texts")}"
      else
        stage_txt = "#{idea_process.stage_sequence_number}. #{tr("Discussion stage","althingi_texts")}"
      end
      latest_idea_process_txt = "#{stage_txt}, #{distance_of_time_in_words_to_now(time)}"
      Rails.cache.write("latest_idea_process_at_#{self.id}", latest_idea_process_txt, :expires_in => 30.minutes)
    end
    latest_idea_process_txt.html_safe if latest_idea_process_txt
  end

  def do_abusive!
    self.user.do_abusive!(notifications)
    self.update_attribute(:flags_count, 0)
  end

  def flag_by_user(user)
    self.increment!(:flags_count)
    for r in User.active.admins
      notifications << NotificationIdeaFlagged.new(:sender => user, :recipient => r)
    end
  end

  def on_published_entry(new_state = nil, event = nil)
    self.published_at = Time.now
    save(:validate => false) if persisted?
  end

  def on_removed_entry(new_state, event)
    [activities, endorsements, points].each do |children|
      children.each do |child|
        child.remove!
      end
    end
    self.removed_at = Time.now
    for r in idea_revisions
      r.remove!
    end
    deactivate_ads_and_refund
    save(:validate => false)
  end

  def on_unremoved_entry(new_state, event)
    self.removed_at = nil
    save(:validate => false)
  end

  def on_buried_entry(new_state, event)
    # should probably send an email notification to the person who submitted it
    # but not doing anything for now.
  end

  def endorsement_by(user)
    endorsement = endorsements.active.find_by_user_id(user.id)
    endorsement if endorsement && endorsement.active?
  end
end
