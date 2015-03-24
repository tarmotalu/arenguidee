class IdeasController < ApplicationController
  XHR_PARTIALS = %w[idea_admin_menu]


  before_filter :authenticate_user!, :only => [
    :comment,
    :consider,
    :create,
    :endorse,
    :endorsed,
    :flag_inappropriate,
    :minu,
    :new,
    :opposed,
    :tag,
    :tag_save,
    :yours_finished,
    :yours_lowest,
    :yours_top,
  ]

  before_filter :authenticate_admin!, :only => [
    :bury,
    :compromised,
    :destroy,
    :edit,
    :failed,
    :intheworks,
    :pending,
    :successful,
    :update,
  ]
  before_filter :load_endorsement, :only => [
    :activities,
    :discussions,
    :endorsed_top_points,
    :endorser_points,
    :endorsers,
    :everyone_points,
    :everyone_points,
    :idea_detail,
    :neutral_points,
    :opposed_top_points,
    :opposer_points,
    :opposers,
    :show,
    :show_feed,
    :top_points,
  ]

  before_filter :check_for_user, :only => [
    :network,
    :yours,
    :yours_created,
    :yours_finished,
  ]

  caches_action :revised, :index, :top, :top_24hr, :top_7days, :top_30days,
                :controversial, :rising, :newest, :finished, :show,
                :top_points, :discussions, :endorsers, :opposers, :activities,
                :if => proc {|c| c.do_action_cache?},
                :cache_path => proc {|c| c.action_cache_path},
                :expires_in => 5.minutes

  def index
    @ideas = Idea.published.all
  end

  def pending
    @title = "Ootel ideed"
    @ideas = Idea.pending.all
    render "admin"
  end

  # GET /ideas/yours
  def yours
    @filter = 'yours'
    @page_title = tr("Your ideas at {sub_instance_name}", "controller/ideas", :sub_instance_name => tr(current_sub_instance.name,"Name from database"))
    @ideas = @user.endorsements.active.by_position.map(&:idea).compact.paginate :include => :idea, :page => params[:page], :per_page => params[:per_page]
    @rss_url = yours_ideas_url(:format => 'rss')
    get_endorsements
    if request.xhr?
      render :partial => 'issues/pageless', :locals => {:ideas => @ideas }
    else
      respond_to do |format|
        format.html { render  :template => "issues/list"}
        format.rss { render :template => "issues/list" }
        format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
        format.xml { render :xml => @ideas.to_xml(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
        format.json { render :json => @ideas.to_json(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
      end
    end
  end

  # GET /ideas/yours_top
  def yours_top
    @page_title = tr("Your ideas ranked highest by {sub_instance_name} members", "controller/ideas", :sub_instance_name => tr(current_sub_instance.name,"Name from database"))
    @ideas = current_user.endorsements.active.by_idea_position.paginate :include => :idea, :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "yours" }
      format.xml { render :xml => @endorsements.to_xml(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @endorsements.to_json(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/yours_lowest
  def yours_lowest
    @page_title = tr("Your ideas ranked lowest by {sub_instance_name} members", "controller/ideas", :sub_instance_name => tr(current_sub_instance.name,"Name from database"))
    @ideas = current_user.endorsements.active.by_idea_lowest_position.paginate :include => :idea, :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "yours" }
      format.xml { render :xml => @endorsements.to_xml(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @endorsements.to_json(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/yours_created
  def yours_created
    @page_title = tr("Ideas you created at {sub_instance_name}", "controller/ideas", :sub_instance_name => tr(current_sub_instance.name,"Name from database"))
    @ideas = @user.created_ideas.published.top_rank.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/network
  def network
    @page_title = tr("Your network's ideas", "controller/ideas", :sub_instance_name => tr(current_sub_instance.name,"Name from database"))
    @rss_url = network_ideas_url(:format => 'rss')
    if @user.followings_count > 0
      @ideas = Endorsement.active.find(:all,
        :select => "endorsements.idea_id, sum((#{Endorsement.max_position+1}-endorsements.position)*endorsements.value) as score, count(*) as endorsements_number, ideas.*",
        :joins => "endorsements INNER JOIN ideas ON ideas.id = endorsements.idea_id",
        :conditions => ["endorsements.user_id in (?) and endorsements.position <= #{Endorsement.max_position}",@user.followings.up.collect{|f|f.other_user_id}],
        :group => "endorsements.idea_id",
        :order => "score desc").paginate :page => params[:page], :per_page => params[:per_page]
        @endorsements = @user.endorsements.active.find(:all, :conditions => ["idea_id in (?)", @ideas.collect {|c| c.idea_id}])
    end
    respond_to do |format|
      format.html
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/yours_finished
  def yours_finished
    @page_title = tr("Your ideas in progress at {sub_instance_name}", "controller/ideas", :sub_instance_name => tr(current_sub_instance.name,"Name from database"))
    @ideas = @user.endorsements.finished.find(:all, :order => "ideas.status_changed_at desc", :include => :idea).paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html { render :action => "yours" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
    if logged_in? and request.format == 'html' and current_user.unread_notifications_count > 0
      for n in current_user.received_notifications.all
        n.read! if n.class == NotificationIdeaFinished and n.unread?
      end
    end
  end

  # GET /ideas/consider
  def consider
    @page_title = tr("Ideas you should consider", "controller/ideas", :sub_instance_name => tr(current_sub_instance.name,"Name from database"))
    @ideas = current_user.recommend(25)
    if @ideas.empty?
      flash[:error] = tr("You need to endorse a few things before we can recommend other ideas for you to consider. Here are a few random ideas to get started.", "controller/ideas")
      redirect_to :action => "random"
      return
    end
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/official
  def official
    @page_title = tr("{official_user_name} ideas", "controller/ideas", :sub_instance_name => tr(current_sub_instance.name,"Name from database"), :official_user_name => current_instance.official_user.name.possessive)
    @rss_url = official_ideas_url(:format => 'rss')
    @ideas = Idea.published.official_endorsed.top_rank.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def minu
    @filter = 'minu'
    @position_in_idea_name = true
    @page_title = tr("My ideas", "contoller/ideas")
    @rss_url = minu_ideas_url(:format => 'rss')
    if params[:category_id]
      @ideas = current_user.ideas_and_points_and_endorsements.compact.paginate :include => :idea, :page => params[:page], :per_page => params[:per_page]
    else
      @ideas = current_user.ideas_and_points_and_endorsements.compact.paginate :include => :idea, :page => params[:page], :per_page => params[:per_page]
    end
    get_endorsements
    if request.xhr?
        render :partial => 'issues/pageless', :locals => {:ideas => @ideas }
    else
      respond_to do |format|
        format.html { render :template => "/issues/list" }
        format.rss { render :action => "list" }
        format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
        format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
        format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
      end
    end
  end

  # GET /ideas/top
  def top
    @filter = 'top'
    @position_in_idea_name = true
    @page_title = tr("Top ideas", "controller/ideas")
    @rss_url = top_ideas_url(:format => 'rss')
    if params[:category_id]
      @ideas = Idea.by_category(params[:category_id]).published.all.sort_by(&:arenguidee_score)
    else
      @ideas = Idea.published.all.sort_by(&:arenguidee_score).reverse
      #.paginate :page => params[:page], :per_page => params[:per_page]
    end
    get_endorsements
    if request.xhr?
        render :partial => 'issues/pageless', :locals => {:ideas => @ideas }
    else
      respond_to do |format|
        format.html { render :template => "ideas/index" }
        format.rss { render :action => "list" }
        format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
        format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
        format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
      end
    end
  end


  def bottom
    @filter = 'bottom'
    @position_in_idea_name = true
    @page_title = tr("Bottom ideas", "controller/ideas")
    @rss_url = top_ideas_url(:format => 'rss')
    if params[:category_id]
      @ideas = Idea.by_category(params[:category_id]).published.sort_by(&:arenguidee_score)
    else
      @ideas = Idea.published.sort_by(&:arenguidee_score)
    end
    get_endorsements
    if request.xhr?
      render :partial => 'issues/pageless', :locals => {:ideas => @ideas }
    else
      respond_to do |format|
        format.html { render :template => "ideas/index" }
        format.rss { render :action => "list" }
        format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
        format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
        format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
      end
    end
  end

  # GET /ideas/top_24hr
  def top_24hr
    @position_in_idea_name = true
    @page_title = tr("Top ideas past 24 hours", "controller/ideas")
    @rss_url = top_ideas_url(:format => 'rss')
    @ideas = Idea.published.top_24hr.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/top_7days
  def top_7days
    @position_in_idea_name = true
    @page_title = tr("Top ideas past 7 days", "controller/ideas")
    @rss_url = top_ideas_url(:format => 'rss')
    @ideas = Idea.published.top_7days.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/top_30days
  def top_30days
    @position_in_idea_name = true
    @page_title = tr("Top ideas past 30 days", "controller/ideas")
    @rss_url = top_ideas_url(:format => 'rss')
    @ideas = Idea.published.top_30days.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/rising
  def rising
    @position_in_idea_name = true
    @page_title = tr("Ideas rising in the rankings", "controller/ideas")
    @rss_url = rising_ideas_url(:format => 'rss')
    @ideas = Idea.published.rising.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/falling
  def falling
    @position_in_idea_name = true
    @page_title = tr("Ideas falling in the rankings", "controller/ideas")
    @rss_url = falling_ideas_url(:format => 'rss')
    @ideas = Idea.published.falling.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/controversial
  def controversial
    @filter = 'controversial'
    @position_in_idea_name = true
    @page_title = tr("Most controversial ideas", "controller/ideas")
    @rss_url = controversial_ideas_url(:format => 'rss')
    @ideas = Idea.published.controversial.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    if request.xhr?
      render :partial => 'issues/pageless', :locals => {:ideas => @ideas }
    else
      respond_to do |format|
        format.html { render :template => "ideas/index"  }
        format.rss { render :action => "list" }
        format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
        format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
        format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
      end
    end
  end

  # GET /ideas/finished
  def finished
    @position_in_idea_name = true
    @page_title = tr("Ideas in progress", "controller/ideas")
    @rss_url = finished_ideas_url(:format => 'rss')
    @ideas = Idea.finished.not_removed.by_most_recent_status_change.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/random
  def random
    @filter = 'random'
    @page_title = tr("Random ideas", "controller/ideas")
    if User.adapter == 'postgresql'
      @ideas = Idea.published.paginate :order => "RANDOM()", :page => params[:page], :per_page => params[:per_page]
    else
      @ideas = Idea.published.paginate :order => "rand()", :page => params[:page], :per_page => params[:per_page]
    end
    get_endorsements
    if request.xhr?
     render :partial => 'issues/pageless', :locals => {:ideas => @ideas }
    else
      respond_to do |format|
        format.html { render  :template => "/issues/list"}
        format.rss { render :action => "list" }
        format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
        format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
        format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
      end
    end
  end


  # GET /ideas/newest
  def newest
    @filter = 'newest'
    @position_in_idea_name = true
    @page_title = tr("Newest ideas", "controller/ideas")
    @rss_url = newest_ideas_url(:format => 'rss')
    @ideas = Idea.published.newest.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    if request.xhr?
        render :partial => 'issues/pageless', :locals => {:ideas => @ideas }
    else
      respond_to do |format|
        format.html { render  :template => "/issues/list"}
        format.rss { render :action => "list" }
        format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
        format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
        format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
      end
    end
  end

  # GET /ideas/untagged
  def untagged
    @page_title = tr("Untagged (or uncategorized) ideas", "controller/ideas")
    @rss_url = untagged_ideas_url(:format => 'rss')
    @ideas = Idea.published.untagged.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "list" }
      format.rss { render :action => "list" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def revised
    @page_title = tr("Recently revised ideas", "controller/ideas", :sub_instance_name => tr(current_sub_instance.name,"Name from database"))
    @ideas = Idea.published.revised.by_recently_revised.uniq.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html
      format.xml { render :xml => @revisions.to_xml(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @revisions.to_json(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def show
    @idea = Idea.find(params[:id])
    @points_up = @idea.points.published.up_value.order("created_at ASC")
    @points_down = @idea.points.published.down_value.order("created_at ASC")
  end

  def show_feed
    last = params[:last].blank? ? Time.now + 1.second : Time.parse(params[:last])
    @activities = @idea.activities.active.top_discussions.feed(last).for_all_users :include => :user
    respond_to do |format|
      format.js
    end
  end

  def opposer_points
    @page_title = tr("Points opposing {idea_name}", "controller/ideas", :idea_name => @idea.name)
    @point_value = -1
    @points = @idea.points.published.by_opposer_helpfulness.paginate :page => params[:page], :per_page => params[:per_page]
    get_qualities
    respond_to do |format|
      format.html { render :action => "points" }
      format.xml { render :xml => @points.to_xml(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def endorser_points
    @page_title = tr("Points supporting {idea_name}", "controller/ideas", :idea_name => @idea.name)
    @point_value = 1
    @points = @idea.points.published.by_endorser_helpfulness.paginate :page => params[:page], :per_page => params[:per_page]
    get_qualities
    respond_to do |format|
      format.html { render :action => "points" }
      format.xml { render :xml => @points.to_xml(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def neutral_points
    @page_title = tr("Points about {idea_name}", "controller/ideas", :idea_name => @idea.name)
    @point_value = 2
    @points = @idea.points.published.by_neutral_helpfulness.paginate :page => params[:page], :per_page => params[:per_page]
    get_qualities
    respond_to do |format|
      format.html { render :action => "points" }
      format.xml { render :xml => @points.to_xml(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def everyone_points
    redirect_to(@idea)
    # @page_title = tr("Best points on {idea_name}", "controller/ideas", :idea_name => @idea.name)
    # @point_value = 0
    # @points = @idea.points.published.by_helpfulness.paginate :page => params[:page], :per_page => params[:per_page]
    # get_qualities
    # respond_to do |format|
    #   format.html { render :action => "points" }
    #   format.xml { render :xml => @points.to_xml(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
    #   format.json { render :json => @points.to_json(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
    # end
  end

  def opposed_top_points
    @page_title = tr("Points opposing {idea_name}", "controller/ideas", :idea_name => @idea.name)
    @point_value = -1
    if params[:by_newest]
      @points = @idea.points.published.down_value.by_recently_created.paginate :page => params[:page], :per_page => params[:per_page]
    else
      @points = @idea.points.published.down_value.by_helpfulness.paginate :page => params[:page], :per_page => params[:per_page]
    end
    get_qualities
    respond_to do |format|
      format.html { render :action => "points" }
      format.xml { render :xml => @points.to_xml(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def endorsed_top_points
    @page_title = tr("Points supporting {idea_name}", "controller/ideas", :idea_name => @idea.name)
    @point_value = 1
    if params[:by_newest]
      @points = @idea.points.published.up_value.by_recently_created.paginate :page => params[:page], :per_page => params[:per_page]
    else
      @points = @idea.points.published.up_value.by_helpfulness.paginate :page => params[:page], :per_page => params[:per_page]
    end
    get_qualities
    respond_to do |format|
      format.html { render :action => "points" }
      format.xml { render :xml => @points.to_xml(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def idea_detail
    setup_top_points(1)
    render :partial=>"ideas/idea_detail", :layout=>false
  end

  def top_points
    @page_title = tr("Top points", "controller/ideas", :idea_name => @idea.name)
    setup_top_points(5)
    respond_to do |format|
      format.html { render :action => "top_points" }
      format.xml { render :xml => @points.to_xml(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:idea, :other_idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def points
    redirect_to :action => "everyone_points"
  end

  def discussions
    @page_title = tr("Discussions on {idea_name}", "controller/ideas", :idea_name => @idea.name)
    @activities = @idea.activities.active.discussions.by_recently_updated.for_all_users.paginate :page => params[:page], :per_page => 10
    #if @activities.empty? # pull all activities if there are no discussions
    #  @activities = @idea.activities.active.paginate :page => params[:page]
    #end
    respond_to do |format|
      format.html { render :action => "activities" }
      format.xml { render :xml => @activities.to_xml(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def comments
    @idea = Idea.find(params[:id])
    @page_title = tr("Latest comments on {idea_name}", "controller/ideas", :idea_name => @idea.name)
    @comments = Comment.published.by_recently_created.find(:all, :conditions => ["activities.idea_id = ?",@idea.id], :include => :activity).paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.rss { render :template => "rss/comments" }
      format.xml { render :xml => @comments.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @comments.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/1/activities
  def activities
    @page_title = tr("Activity on {idea_name}", "controller/ideas", :idea_name => @idea.name)
    @activities = @idea.activities.active.for_all_users.by_recently_created.paginate :include => :user, :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.rss { render :template => "rss/activities" }
      format.xml { render :xml => @activities.to_xml(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/1/endorsers
  def endorsers
    @page_title = tr("{number} people endorse {idea_name}", "controller/ideas", :idea_name => @idea.name, :number => @idea.up_endorsements_count)
    if request.format != 'html'
      @endorsements = @idea.endorsements.active_and_inactive.endorsing.paginate :page => params[:page], :per_page => params[:per_page], :include => :user
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @endorsements.to_xml(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @endorsements.to_json(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # GET /ideas/1/opposers
  def opposers
    @page_title = tr("{number} people opposed {idea_name}", "controller/ideas", :idea_name => @idea.name, :number => @idea.down_endorsements_count)
    if request.format != 'html'
      @endorsements = @idea.endorsements.active_and_inactive.opposing.paginate :page => params[:page], :per_page => params[:per_page], :include => :user
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @endorsements.to_xml(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @endorsements.to_json(:include => :user, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def new
    @categories = Category.sorted.all
    @idea ||= Idea.new
    @idea.category = Category.find(params[:category_id]) if params[:category_id]
  end

  def edit
    @idea = Idea.find(params[:id])
  end

  def access_denied
    flash[:error] = tr('Access denied', 'ideas')
    redirect_to '/ideas/'
  end

   def create
     @idea = Idea.new({"status" => "pending"}.merge(idea_params))
     @idea.user = current_user
     @idea.ip_address = request.remote_ip

     return render "new", :status => :unprocessable_entity if !@idea.save

     unless @idea.points.empty?
       first_point = @idea.points.first
       first_point.setup_revision
       first_point.reload
       @endorsement = @idea.endorse(current_user,request,current_sub_instance,@referral)
       quality = first_point.point_qualities.find_or_create_by_user_id_and_value(current_user.id, true)
     end

     IdeaRevision.create_from_idea(@idea,request.remote_ip,request.env["HTTP_USER_AGENT"])

     redirect_to @idea
   end

  def endorse
    @idea = Idea.find(params[:id])
    @endorsement = @idea.endorse(current_user, request)

    respond_to do |format|
      format.js { render :partial => "endorsements/buttons" }
    end
  end

  def oppose
    @idea = Idea.find(params[:id])
    @endorsement = @idea.oppose(current_user, request)

    respond_to do |format|
      format.js { render :partial => "endorsements/buttons" }
    end
  end

  def update
    # Only admins allowed to update for now.
    @idea = Idea.find(params[:id])

    if @idea.update_attributes(idea_params)
      respond_to do |format|
        format.html { redirect_to @idea }
        partial = XHR_PARTIALS.include?(params[:partial]) && params[:partial]
        format.js { render :partial => params[:partial] } if partial
      end
    else
      render "edit", :status => :unprocessable_entity
    end
  end

  # PUT /ideas/1/create_short_url
  def create_short_url
    @idea = Idea.find(params[:id])
    @short_url = @idea.create_short_url
    if @short_url
      @idea.save(:validate => false)
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace "idea_short_url", render(:partial => "ideas/short_url", :locals => {:idea => @idea})
          page << "short_url.select();"
        end
      }
    end
  end

  # PUT /ideas/1/flag_inappropriate
  def flag
    @idea = Idea.find(params[:id])
    @idea.flag_by_user(current_user)

    respond_to do |format|
      format.html { redirect_to(comments_url) }
      format.js {
        render :update do |page|
          if current_user.is_admin?
            page.replace_html "idea_report_#{@idea.id}", render(:partial => "ideas/report_content", :locals => {:idea => @idea})
          else
            page.replace_html "idea_report_#{@idea.id}","<div class='warning_inline'> #{tr("Thanks for bringing this to our attention", "controller/ideas")}</div>"
          end
        end
      }
    end
  end

  def abusive
    @idea = Idea.find(params[:id])
    @idea.do_abusive!
    @idea.remove!
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html "idea_flag_#{@idea.id}", "<div class='warning_inline'>#{tr("The content has been deleted and a warning_sent", "controller/ideas")}</div>"
        end
      }
    end
  end

  def not_abusive
    @idea = Idea.find(params[:id])
    @idea.update_attribute(:flags_count, 0)
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html "idea_flag_#{@idea.id}",""
        end
      }
    end
  end

  # PUT /ideas/1/bury
  def bury
    @idea = Idea.find(params[:id])
    @idea.bury!
    ActivityIdeaBury.create(:idea => @idea, :user => current_user, :sub_instance => current_sub_instance)
    respond_to do |format|
      flash[:notice] = tr("{idea_name} is now buried, it will no longer be displayed in the charts.", "controller/ideas", :idea_name => @idea.name)
      format.html { redirect_to(@idea) }
    end
  end

  # PUT /ideas/1/successful
  def successful
    @idea = Idea.find(params[:id])
    @idea.successful!
    respond_to do |format|
      flash[:notice] = tr("{idea_name} is now marked finished and successful", "controller/ideas", :idea_name => @idea.name)
      format.html { redirect_to(@idea) }
    end
  end

  # PUT /ideas/1/intheworks
  def intheworks
    @idea = Idea.find(params[:id])
    @idea.intheworks!
    respond_to do |format|
      flash[:notice] = tr("{idea_name} is now marked 'in the works'", "controller/ideas", :idea_name => @idea.name)
      format.html { redirect_to(@idea) }
    end
  end

  # PUT /ideas/1/failed
  def failed
    @idea = Idea.find(params[:id])
    @idea.failed!
    respond_to do |format|
      flash[:notice] = tr("{idea_name} is now marked finished and failed", "controller/ideas", :idea_name => @idea.name)
      format.html { redirect_to(@idea) }
    end
  end

  # PUT /ideas/1/compromised
  def compromised
    @idea = Idea.find(params[:id])
    @idea.compromised!
    respond_to do |format|
      flash[:notice] = tr("{idea_name} is now marked finished but compromised", "controller/ideas", :idea_name => @idea.name)
      format.html { redirect_to(@idea) }
    end
  end

  def endorsed
    @idea = Idea.find(params[:id])
    @endorsement = @idea.endorse(current_user,request,current_sub_instance,@referral)
    redirect_to @idea
  end

  def opposed
    @idea = Idea.find(params[:id])
    @endorsement = @idea.oppose(current_user,request,current_sub_instance,@referral)
    redirect_to @idea
  end

  # GET /ideas/1/tag
  def tag
    @idea = Idea.find(params[:id])
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'idea_' + @idea.id.to_s + '_tags', render(:partial => "ideas/tag", :locals => {:idea => @idea})
          page['idea_' + @idea.id.to_s + "_issue_list"].focus
        end
      }
    end
  end

  # POST /ideas/1/tag
  def tag_save
    @idea = Idea.find(params[:id])
    @idea.update_attributes(params[:idea])
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'idea_' + @idea.id.to_s + '_tags', render(:partial => "ideas/tag_show", :locals => {:idea => @idea})
        end
      }
    end
  end

  def destroy
    @idea = Idea.find(params[:id])
    @idea.destroy
    redirect_to ideas_path
  end

  def statistics
    @idea = Idea.find(params[:id])
    respond_to do |format|
      format.html
      format.js { render_to_facebox }
    end
  end

  private

    def get_endorsements
      @endorsements = nil
      if logged_in? # pull all their endorsements on the ideas shown
        @endorsements = current_user.endorsements.active.find(:all, :conditions => ["idea_id in (?)", @ideas.compact.collect {|c| c.id}])
      end
    end

    def load_endorsement
      @idea = Idea.unscoped.find(params[:id])
      if @idea.status == 'removed' or @idea.status == 'abusive'
        flash[:notice] = tr("That idea was deleted", "controller/ideas")
        redirect_to "/"
        return false
      end

      @endorsement = nil
      if logged_in? # pull all their endorsements on the ideas shown
        @endorsement = @idea.endorsements.active.find_by_user_id(current_user.id)
      end
    end

    def get_qualities(multi_points=nil)
      if multi_points
        @points=[]
        multi_points.each do |points|
          @points+=points
        end
      end
      if not @points.empty?
        @qualities = nil
        if logged_in? # pull all their qualities on the ideas shown
          @qualities = PointQuality.find(:all, :conditions => ["point_id in (?) and user_id = ? ", @points.collect {|c| c.id},current_user.id])
        end
      end
    end

    def setup_top_points(limit)
      @point_value = 0
      @points_top_up = Point.unscoped.where(idea_id: @idea.id).published.by_helpfulness.up_value.limit(limit)
      @points_top_down = Point.unscoped.where(idea_id: @idea.id).published.by_helpfulness.down_value.limit(limit)
      @points_new_up = Point.unscoped.where(idea_id: @idea.id).published.by_recently_created.up_value.limit(limit).reject {|p| @points_top_up.include?(p)}
      @points_new_down = Point.unscoped.where(idea_id: @idea.id).published.by_recently_created.down_value.limit(limit).reject {|p| @points_top_down.include?(p)}
      @total_up_points = Point.unscoped.where(idea_id: @idea.id).published.up_value.count
      @total_down_points = Point.unscoped.where(idea_id: @idea.id).published.down_value.count
      @total_up_points_new = [0,@total_up_points-@points_top_up.length].max
      @total_down_points_new = [0,@total_down_points-@points_top_down.length].max
      get_qualities([@points_new_up,@points_new_down,@points_top_up,@points_top_down])
    end

    def check_for_user
      if params[:user_id]
        @user = User.find(params[:user_id])
      elsif logged_in?
        @user = current_user
      else
        access_denied and return
      end
    end

  private
  def idea_params
    allowed_params = %w[name name description text category_id attachment video_url]
    allowed_params.push "status" if current_user.admin?
    allowed_params.push "author_name" if current_user.admin?
    params[:idea].slice(*allowed_params) if params[:idea]
  end
end
