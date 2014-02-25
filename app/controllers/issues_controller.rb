class IssuesController < ApplicationController
  before_filter :check_for_user, :only => [:yours, :yours_finished, :yours_created, :network]
  before_filter :authenticate_user!, :only => [:minu]

  def index
    @page_title =  tr("Categories", "controller/issues")
    @categories = Category.sorted.all
    @sub_instance_tags = []

    respond_to do |format|
      format.html {
        if current_instance.tags_page == 'cloud'
          render :template => "issues/cloud"
        elsif current_instance.tags_page == 'list'
          render :template => "issues/index"
        end
      }
      format.xml { render :xml => @issues.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @issues.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def show
    if params[:page] =~ /\D*/
      params[:page].gsub!(/\D/, '')
    end

    if params[:action] != 'show'
      @filter = params[:action].to_s
      scpe = params[:action].to_sym
    else
      @filter = 'newest'
      scpe = :newest
    end

    @category = Category.find(params[:id])
    @page_title = @category.name

    @ideas = @category.ideas.published
    @ideas = @ideas.send(scpe).paginate(:page => params[:page], :per_page => params[:per_page])

    get_endorsements

    if request.xhr?
      render :partial => 'issues/ideas', :locals => {:ideas => @ideas }
    else
      respond_to do |format|
        format.html { render :action => "show" }
        format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
        format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
        format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
      end
    end
  end

  alias :top :show
  alias :bottom :show
  alias :newest :show
  alias :random :show

  def minu
    @filter = 'minu'
    @position_in_idea_name = true
    @page_title = tr("My ideas", "contoller/ideas")
    @rss_url = minu_ideas_url(:format => 'rss')
    @category = Category.find(params[:id])
    @ideas = current_user.ideas_and_points_and_endorsements.delete_if{|x| x.category_id != @category.id}.compact.paginate :include => :idea, :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    if request.xhr?
        render :partial => 'issues/ideas', :locals => {:ideas => @ideas }
    else
      respond_to do |format|
        format.html { render :action => "show" }
        format.rss { render :action => "show" }
        format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
        format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
        format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
      end
    end
  end

  def yours

    @filter = 'yours'
    @category = Category.find(params[:id])
    @page_title = tr("Your {tag_name} ideas", "controller/issues", :tag_name => tr(@category.name, "model/category").titleize)
    @ideas = @user.ideas.where(category_id: @category.id).paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements if logged_in?
    respond_to do |format|
      format.html { render :action => "show" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def yours_finished
    @category = Category.find(params[:id])
    @page_title = tr("Your finished {tag_name} ideas", "controller/issues", :tag_name => tr(@category.name, "model/category").titleize)
    @ideas = @user.finished_ideas.finished.where(category_id: @category.id).order("ideas.status_changed_at desc").paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html { render :action => "show" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def yours_created
    @category = Category.find(params[:id])
    @page_title = tr("{tag_name} ideas you created", "controller/issues", :tag_name => tr(@category.name, "model/category").titleize)
    @ideas = @user.created_ideas.where(category_id: @category.id).paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements if logged_in?
    respond_to do |format|
      format.html { render :action => "show" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def network
    @category = Category.find(params[:id])
    @page_title = tr("Your network's {tag_name} ideas", "controller/issues", :tag_name => tr(@category.name, "model/category").titleize)
    @tag_ideas = Idea.published.where(category_id: @category.id)
    if @user.followings_count > 0
      @ideas = Endorsement.active.find(:all,
        :select => "endorsements.idea_id, sum((#{Endorsement.max_position+1}-endorsements.position)*endorsements.value) as score, count(*) as endorsements_number, ideas.*",
        :joins => "endorsements INNER JOIN ideas ON ideas.id = endorsements.idea_id",
        :conditions => ["endorsements.user_id in (?) and endorsements.position <= #{Endorsement.max_position} and endorsements.idea_id in (?)",@user.followings.up.collect{|f|f.other_user_id}, @tag_ideas.collect{|p|p.id}],
        :group => "endorsements.idea_id",
        :order => "score desc").paginate :page => params[:page]
        if logged_in?
          @endorsements = current_user.endorsements.active.find(:all, :conditions => ["idea_id in (?)", @ideas.collect {|c| c.idea_id}])
        end
    end
    respond_to do |format|
      format.html
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:include => :idea, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:include => :idea, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def rising
    @category = Category.find(params[:id])
    @page_title = tr("Rising {tag_name} ideas", "controller/issues", :tag_name => tr(@category.name, "model/category").titleize)
    @ideas = Idea.where(category_id: @category.id).published.rising.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "show" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def falling
    @category = Category.find(params[:id])
    @page_title = tr("Falling {tag_name} ideas", "controller/issues", :tag_name => tr(@category.name, "model/category").titleize)
    @ideas = Idea.where(category_id: @category.id).falling.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "show" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def controversial
    @filter = 'controversial'
    @category = Category.find(params[:id])
    @page_title = tr("Controversial {tag_name} ideas", "controller/issues", :tag_name => tr(@category.name, "model/category").titleize)
    @ideas = Idea.where(category_id: @category.id).published.controversial.paginate :page => params[:page], :per_page => params[:per_page]
    get_endorsements
    respond_to do |format|
      format.html { render :action => "show" }
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # this doesn't work in pgsql :(
  def random
    @filter = 'random'
    @category = Category.find(params[:id])
    @page_title = tr("Random {tag_name} ideas", "controller/issues", :tag_name => tr(@category.name, "model/category").titleize)
    if User.adapter == 'postgresql'
      flash[:error] = "This page doesn't work, sorry."
      redirect_to "/issues/" + @tag.slug
      return
    else
      @ideas = Idea.where(category_id: @category).published.paginate :order => "rand()", :page => params[:page], :per_page => params[:per_page]
    end
    get_endorsements
    if request.xhr?
      render :partial => 'issues/ideas', :locals => {:ideas => @ideas }
    else
      respond_to do |format|
        format.html { render :action => "show" }
        format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
        format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
        format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
      end
    end
  end

  def finished
    @category = Category.find(params[:id])
    @page_title = tr("Finished {tag_name} ideas", "controller/issues", :tag_name => tr(@category.name, "model/category").titleize)
    @ideas = Idea.where(category_id: @category.id).finished.by_most_recent_status_change.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html
      format.js { render :layout => false, :text => "document.write('" + js_help.escape_javascript(render_to_string(:layout => false, :template => 'ideas/list_widget_small')) + "');" }
      format.xml { render :xml => @ideas.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def discussions
    @category = Category.find(params[:id])
    @page_title = tr("Discussions on {tag_name}", "controller/issues", :tag_name => tr(@category.name, "model/category").titleize)
    @ideas = Idea.where(category_id: @category.id)
    @activities = Activity.active.discussions.for_all_users.by_recently_updated.find(:all, :conditions => ["idea_id in (?)",@ideas.collect{|p| p.id}]).paginate :page => params[:page], :per_page => params[:per_page], :per_page => 10
    respond_to do |format|
      format.html
      format.xml { render :xml => @activities.to_xml(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def points
    @category = Category.find(params[:id])
    @page_title = tr("{tag_name} points", "controller/issues", :tag_name => tr(@category.name, "model/category").titleize)
    @ideas = Idea.where(category_id: @category.id)
    @points = Point.by_helpfulness.find(:all, :conditions => ["idea_id in (?)",@ideas.collect{|p| p.id}]).paginate :page => params[:page], :per_page => params[:per_page]
    @qualities = nil
    if logged_in? and @points.any? # pull all their qualities on the points shown
      @qualities = PointQuality.find(:all, :conditions => ["point_id in (?) and user_id = ? ", @points.collect {|c| c.id},current_user.id])
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @points.to_xml(:include => [:idea,:other_idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:idea,:other_idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def twitter
    @page_title = tr("What people are saying right now about {tag_name}", "controller/issues", :tag_name => tr(@tag_names, "model/category").titleize)
  end

  private
  def get_endorsements
    @endorsements = nil
    if logged_in? # pull all their endorsements on the ideas shown
      @endorsements = Endorsement.find(:all, :conditions => ["idea_id in (?) and user_id = ? and status='active'", @ideas.collect {|c| c.id},current_user.id])
    end
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
end

