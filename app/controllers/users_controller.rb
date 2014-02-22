class UsersController < ApplicationController
  before_filter :authenticate_user!, :only => [
    :edit,
    :endorse,
    :follow,
    :resend_activation,
    :resend_activation,
    :signups,
    :unfollow,
  ]

  before_filter :authenticate_admin!, :only => [
    :impersonate,
    :index,
    :make_admin,
    :suspend,
    :unsuspend,
  ]

  caches_action :show,
                :if => proc {|c| c.do_action_cache? },
                :cache_path => proc {|c| c.action_cache_path},
                :expires_in => 5.minutes

  def index
    @users = User.all
  end

  def edit
    @user = User.find(params[:id])

    unless current_user.is_admin?
      if current_user != @user || check_for_suspension
        redirect_to '/' and return
      end
    end
    @page_title = tr("Changing settings for {user_name}", "controller/users", :user_name => @user.name)
  end

  def update
    @user = User.find(params[:id])
    unless current_user.is_admin?
      if current_user != @user || check_for_suspension
        redirect_to '/' and return
      end
    end
    @page_title = tr("Changing settings for {user_name}", "controller/users", :user_name => @user.name)
    unless current_user.is_admin?
      params[:user].delete :first_name
      params[:user].delete :last_name
      params[:user].delete :is_admin
      params[:user].delete :login
    end

    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = tr("Saved settings for {user_name}", "controller/users", :user_name => @user.name)
        @page_title = tr("Changing settings for {user_name}", "controller/users", :user_name => @user.name)
        format.html { redirect_to @user }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
      end
    end
  end

  def show
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    @page_title = tr("{user_name} at {instance_name}", "controller/users", :user_name => @user.name, :instance_name => tr(current_instance.name,"Name from database"))
    @ideas = Idea.where(:user_id => @user.id).published.top_rank
    @endorsements = nil
    get_following
    if logged_in? # pull all their endorsements on the ideas shown
      @endorsements = Endorsement.find(:all, :conditions => ["idea_id in (?) and user_id = ? and status='active'", @ideas.collect {|c| c.id},current_user.id])
    end
    @activities = @user.activities.active.by_recently_created.paginate :include => :user, :page => params[:page], :per_page => params[:per_page]

    @endorsements = nil
    if logged_in? # pull all their endorsements on the ideas shown
      @endorsements = Endorsement.find(:all, :conditions => ["idea_id in (?) and user_id = ? and status='active'", @ideas.collect {|c| c.id},current_user.id])
    end

    respond_to do |format|
      format.html
      format.xml { render :xml => @user.to_xml(:methods => [:revisions_count], :include => [:top_endorsement, :referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @user.to_json(:methods => [:revisions_count], :include => [:top_endorsement, :referral, :sub_instance_referral], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def ideas
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension

    @ideas = Idea.where(:user_id => @user.id).published.top_rank
    @page_title = @user.name
    @points = Point.where(:user_id => @user.id).published
    @supporting = @user.endorsements.active.by_position.delete_if{|x| @ideas.map(&:id).include?(x.idea_id)}
    @endorsements = nil
    get_following
    if logged_in? # pull all their endorsements on the ideas shown
      @endorsements = Endorsement.find(:all, :conditions => ["idea_id in (?) and user_id = ? and status='active'", @supporting.collect {|c| c.idea_id},current_user.id])
    end
    @ideas.compact!

    respond_to do |format|
      format.html
      format.xml { render :xml => @ideas.to_xml(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @ideas.to_json(:include => [:idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def activities
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    get_following
    @page_title = tr("What {user_name} is doing at {instance_name}", "controller/users", :user_name => @user.name, :instance_name => tr(current_instance.name,"Name from database"))
    @activities = @user.activities.active.by_recently_created.paginate :page => params[:page], :per_page => params[:per_page]
    if request.xhr?
      render :partial => 'feed/activity_list'#, :locals => {:activities => @activities}
    else
      respond_to do |format|
        format.html # show.html.erb
        format.rss { render :template => "rss/activities" }
        format.xml { render :xml => @activities.to_xml(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
        format.json { render :json => @activities.to_json(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
      end
    end
  end

  def comments
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    @page_title = tr("{user_name} comments at {instance_name}", "controller/users", :user_name => @user.name.possessive, :instance_name => tr(current_instance.name,"Name from database"))
    @comments = @user.comments.published.by_recently_created.find(:all, :include => :activity).paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.rss { render :template => "rss/comments" }
      format.xml { render :xml => @comments.to_xml(:except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @comments.to_json(:except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def discussions
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    get_following
    @page_title = tr("{user_name} discussions at {instance_name}", "controller/users", :user_name => @user.name.possessive, :instance_name => tr(current_instance.name,"Name from database"))
    @activities = @user.activities.active.discussions.by_recently_created.paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html { render :template => "users/activities" }
      format.xml { render :xml => @activities.to_xml(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @activities.to_json(:include => :comments, :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def capital
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    get_following
    @page_title = tr("{user_name} {currency_name} at {instance_name}", "controller/users", :user_name => @user.name.possessive, :currency_name => tr(current_instance.currency_name.downcase,"Currency name from database"), :instance_name => tr(current_instance.name,"Name from database"))
    @activities = @user.activities.active.capital.by_recently_created.paginate :page => params[:page], :per_page => params[:per_page]
    if request.xhr?
      render :partial => "feed/activity_list"
    else
      respond_to do |format|
        format.html {
          render :template => "users/activities"
        }
        format.xml { render :xml => @activities.to_xml(:include => :capital, :except => NB_CONFIG['api_exclude_fields']) }
        format.json { render :json => @activities.to_json(:include => :capital, :except => NB_CONFIG['api_exclude_fields']) }
      end
    end
  end

  def points
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    get_following
    @page_title = tr("{user_name} points at {instance_name}", "controller/users", :user_name => @user.name.possessive, :instance_name => tr(current_instance.name,"Name from database"))
    @points = @user.points.published.by_recently_created.paginate :page => params[:page], :per_page => params[:per_page]
    if logged_in? and @points.any? # pull all their qualities on the points shown
      @qualities = PointQuality.find(:all, :conditions => ["point_id in (?) and user_id = ? ", @points.collect {|c| c.id},current_user.id])
    end
    respond_to do |format|
      format.html
      format.xml { render :xml => @points.to_xml(:include => [:idea,:other_idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @points.to_json(:include => [:idea,:other_idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def activate
    self.current_user = params[:activation_code].blank? ? false : User.find_by_activation_code(params[:activation_code])
    if logged_in? && !current_user.active?
      current_user.activate!
    end
    flash[:notice] = tr("Thanks for verifying your email address", "controller/users")
    redirect_back_or_default('/')
  end

  def resend_activation
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    @user.resend_activation
    flash[:notice] = tr("Resent verification email to {email}", "controller/users", :email => @user.email)
    redirect_back_or_default(url_for(@user))
  end

  def follow
    @value = params[:value].to_i
    @user = User.find(params[:id])
    if @value == 1
      @following = current_user.follow(@user)
    else
      @following = current_user.ignore(@user)
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          if params[:region] == 'user_left'
            page.replace_html 'user_' + @user.id.to_s + "_button",render(:partial => "users/button_small", :locals => {:user => @user, :following => @following})
          end
        end
      }
    end
  end

  def unfollow
    @value = params[:value].to_i
    @user = User.find(params[:id])
    if @value == 1
      current_user.unfollow(@user)
    else
      current_user.unignore(@user)
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          if params[:region] == 'user_left'
            page.replace_html 'user_' + @user.id.to_s + "_button",render(:partial => "users/button_small", :locals => {:user => @user, :following => nil})
          end
        end
      }
    end
  end

  def followers
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    get_following
    @page_title = tr("{count} people are following {user_name}", "controller/users", :user_name => @user.name, :count => @user.followers_count)
    @followings = @user.followers.up.paginate :page => @page, :per_page => 50
    respond_to do |format|
      format.html
      format.xml { render :xml => @followings.to_xml(:include => [:user], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @followings.to_json(:include => [:user], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def ignorers
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    get_following
    @page_title = tr("{count} people are ignoring {user_name}", "controller/users", :user_name => @user.name, :count => @user.ignorers_count)
    @followings = @user.followers.down.paginate :page => @page, :per_page => 50
    respond_to do |format|
      format.html { render :action => "followers" }
      format.xml { render :xml => @followings.to_xml(:include => [:user], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @followings.to_json(:include => [:user], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def following
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    get_following
    @page_title = tr("{user_name} is following {count} people", "controller/users", :user_name => @user.name, :count => @user.followings_count)
    @followings = @user.followings.up.paginate :page => @page, :per_page => 50
    respond_to do |format|
      format.html
      format.xml { render :xml => @followings.to_xml(:include => [:other_user], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @followings.to_json(:include => [:other_user], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  def ignoring
    @user = User.find(params[:id])
    redirect_to '/' and return if check_for_suspension
    get_following
    @page_title = tr("{user_name} is ignoring {count} people", "controller/users", :user_name => @user.name, :count => @user.ignorings_count)
    @followings = @user.followings.down.paginate :page => @page, :per_page => 50
    respond_to do |format|
      format.html { render :action => "following" }
      format.xml { render :xml => @followings.to_xml(:include => [:other_user], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @followings.to_json(:include => [:other_user], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end

  # this is for loading up more endorsements in the left column
  def endorsements
    session[:endorsement_page] = (params[:page]||1).to_i
    respond_to do |format|
      format.js {
        render :update do |page|
          #page.replace_html 'your_ideas_container', :partial => "ideas/yours"
        end
      }
    end
  end

  def order
    order = params[:your_ideas]
    endorsements = Endorsement.find(:all, :conditions => ["id in (?)", params[:your_ideas]], :order => "position asc")
    order.each_with_index do |id, position|
      if id
        endorsement = endorsements.detect {|e| e.id == id.to_i }
        new_position = (((session[:endorsement_page]||1)*25)-25)+position + 1
        if endorsement and endorsement.position != new_position
          endorsement.insert_at(new_position)
          endorsements = Endorsement.find(:all, :conditions => ["id in (?)", params[:your_ideas]], :order => "position asc")
        end
      end
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          #page.replace_html 'your_ideas_container', :partial => "ideas/yours"
          #page.replace_html 'your_ideas_container', order.inspect
        end
      }
    end
  end

  def suspend
    @user = User.find(params[:id])
    @user.suspend!
    redirect_to(@user)
  end

  def unsuspend
    @user = User.find(params[:id])
    @user.unsuspend!
    flash[:notice] = tr("{user_name} has been reinstated", "controller/users", :user_name => @user.name)
    redirect_to request.referer
  end

  # this isn't actually used, but the current_user will endorse ALL of this user's ideas
  def endorse
    if not logged_in?
      session[:endorse_user] = params[:id]
      access_denied
      return
    end
    @user = User.find(params[:id])
    for e in @user.endorsements.active
      e.idea.endorse(current_user,request,current_sub_instance,@referral) if e.is_up?
      e.idea.oppose(current_user,request,current_sub_instance,@referral) if e.is_down?
    end
    respond_to do |format|
      format.js { redirect_from_facebox(user_path(@user)) }
    end
  end

  def impersonate
    @user = User.find(params[:id])
    self.current_user = @user
    flash[:notice] = tr("You are now logged in as {user_name}", "controller/users", :user_name => @user.name)
    redirect_to @user
    return
  end

  def make_admin
    # redirect_to '/' and return
    @user = User.find(params[:id])
    @user.is_admin = true
    @user.save(:validate => false)
    flash[:notice] = tr("{user_name} is now an Administrator", "controller/users", :user_name => @user.name)
    redirect_to @user
  end

  private
  def get_following
    if logged_in?
      @following = @user.followers.find_by_user_id(current_user.id)
    else
      @following = nil
    end
  end

  def check_for_suspension
    if @user.status == 'suspended'
      flash[:error] = tr("{user_name} is suspended", "controller/users", :user_name => @user.name)
      if logged_in? and current_user.is_admin?
      else
        return true
      end
    end
    if @user.status == 'removed'
      flash[:error] = tr("That user deleted their account", "controller/users")
      return true
    end
  end
end
