require 'will_paginate/array'

class ApplicationController < ActionController::Base
  include FaceboxRender
  protect_from_forgery

  helper :all
  # Make these methods visible to views as well
  helper_method :current_facebook_user, :instance_cache, :current_sub_instance, :current_user_endorsements, :current_idea_ids, :current_following_ids, :current_ignoring_ids, :current_following_facebook_uids, :current_instance, :current_tags, :facebook_session, :is_robot?, :js_help, :logged_in?

  before_filter :update_activity_time

  before_filter :load_actions_to_publish, :unless => [:is_robot?]
    
  before_filter :check_blast_click, :unless => [:is_robot?]
  before_filter :check_idea, :unless => [:is_robot?]
  before_filter :check_referral, :unless => [:is_robot?]
  before_filter :check_suspension, :unless => [:is_robot?]
  before_filter :update_loggedin_at, :unless => [:is_robot?]
  before_filter :init_tr8n
  before_filter :check_google_translate_setting

  before_filter :setup_inline_translation_parameters
  before_filter :get_categories

  helper_method :is_admin?

  def is_admin?
    current_user && current_user.is_admin?
  end

  def authenticate_admin!
    return if current_user && current_user.admin?

    respond_to do |format|
      format.html do
        flash[:notice] = "You must be an admin to do that."
        redirect_to root_path
      end
    end
  end
  alias admin_required authenticate_admin!

  protected
  def logged_in?
    current_user.present?
  end

  def action_cache_path
    params.merge({:host=>request.host, :country_code=>@country_code,
                  :locale=>session[:locale], :google_translate=>session[:enable_google_translate],
                  :have_shown_welcome=>session[:have_shown_welcome], 
                  :last_selected_language=>cookies[:last_selected_language],
                  :flash=>flash.map {|k,v| "#{v}" }.join.parameterize})
  end

  def do_action_cache?
    if logged_in?
      false
    elsif request.format.html?
      true
    else
      false
    end
  end

  def get_categories
    @categories = Category.all
    session[:locale] = "et"
  end

  def update_activity_time
    if current_user and current_user.is_admin?
      session[:expires_at] = 6.hours.from_now
    else
      session[:expires_at] = 1.hour.from_now
    end
  end

  def setup_inline_translation_parameters
    @inline_translations_allowed = false
    @inline_translations_enabled = false

    if logged_in? and Tr8n::Config.current_user_is_translator?
      Tr8n::Config.current_translator.reload # workaround for broken tr8n
      unless Tr8n::Config.current_translator.blocked?
        @inline_translations_allowed = true
        @inline_translations_enabled = Tr8n::Config.current_translator.enable_inline_translations?
      end
    elsif logged_in?
      @inline_translations_allowed = Tr8n::Config.open_registration_mode?
    end

    @inline_translations_allowed = true if Tr8n::Config.current_user_is_admin?
  end
        
  def unfrozen_instance(object)
    eval "#{object.class}.where(:id=>object.id).first"
  end

  # Will either fetch the current sub_instance or return nil if there's no subdomain
  def current_sub_instance
    if Rails.env.development?
      begin
        if params[:sub_instance_short_name]
          if params[:sub_instance_short_name].empty?
            session.delete(:set_sub_instance_id)
            SubInstance.current = @current_sub_instance = nil
          else
            @current_sub_instance = SubInstance.find_by_short_name(params[:sub_instance_short_name])
            SubInstance.current = @current_sub_instance
            session[:set_sub_instance_id] = @current_sub_instance.id
          end
        elsif session[:set_sub_instance_id]
          @current_sub_instance = SubInstance.find(session[:set_sub_instance_id])
          SubInstance.current = @current_sub_instance
        end
      end
    end
    @current_sub_instance ||= SubInstance.find_by_short_name(request.subdomains.first)
    if @iso_country
      Rails.logger.info ("Setting sub instance to iso countr #{@iso_country.id}")
      @current_sub_instance ||= SubInstance.where(:iso_country_id=>@iso_country.id).first
    end
    @current_sub_instance ||= SubInstance.find_by_short_name("united-nations")
    @current_sub_instance ||= SubInstance.find_by_short_name("www")
    SubInstance.current = @current_sub_instance
  end
  
  def current_locale
    I18n.locale = "et"
    tr8n_current_locale = "et"
    session[:locale] = "et"
    tr8n_user_preffered_locale  = "et"
    return "et"
#     if params[:locale]
#       session[:locale] = params[:locale]
#       cookies.permanent[:last_selected_language] = session[:locale]
#       Rails.logger.debug("Set language from params")
#     elsif not session[:locale]
#       if cookies[:last_selected_language]
#         session[:locale] = cookies[:last_selected_language]
#         Rails.logger.debug("Set language from cookie")
# #      elsif Instance.current.layout == "application"
# #        session[:locale] = "en"
# #        Rails.logger.info("Set language for application to English")
#       elsif @iso_country and not @iso_country.languages.empty?
#         session[:locale] =  @iso_country.languages.first.locale
#         Rails.logger.debug("Set language from geoip")
#       elsif SubInstance.current and SubInstance.current.default_locale
#         session[:locale] = SubInstance.current.default_locale
#         Rails.logger.debug("Set language from sub_instance")
#       else
#         session[:locale] = tr8n_user_preffered_locale
#         Rails.logger.debug("Set language from tr8n")
#       end
#     else
#       Rails.logger.debug("Set language from session")
#     end
#     session_locale = session[:locale]
#     if ENABLED_I18_LOCALES.include?(session_locale)
#       I18n.locale = session_locale
#     else
#       session_locale = session_locale.split("-")[0] if session_locale.split("-").length>1
#       I18n.locale = ENABLED_I18_LOCALES.include?(session_locale) ? session_locale : "en"
#     end
#     tr8n_current_locale = session[:locale]
  end

  def check_google_translate_setting
    if params[:gt]
      if params[:gt]=="1"
        session[:enable_google_translate] = true
      else
        session[:enable_google_translate] = nil
      end
    end
    
    @google_translate_enabled_for_locale = Tr8n::Config.current_language.google_key
  end

  def current_instance
    return @current_instance if @current_instance
    @current_instance = Rails.cache.read('instance')
    if not @current_instance
      @current_instance = Instance.last
      if @current_instance
        @current_instance.update_counts
        Rails.cache.write('instance', @current_instance, :expires_in => 15.minutes)
      else
        return nil
      end
    end
    Instance.current = @current_instance
    return @current_instance
  end
  
  def current_user_endorsements
		@current_user_endorsements ||= current_user.endorsements.active.by_position.paginate(:include => :idea, :page => session[:endorsement_page], :per_page => 25)
  end
  
  def current_idea_ids
    return [] unless logged_in? and current_user.endorsements_count > 0
    @current_idea_ids ||= current_user.endorsements.active_and_inactive.collect{|e|e.idea_id}
  end  
  
  def current_following_ids
    return [] unless logged_in? and current_user.followings_count > 0
    @current_following_ids ||= current_user.followings.up.collect{|f|f.other_user_id}
  end
  
  def current_following_facebook_uids
    return [] unless logged_in? and current_user.followings_count > 0 and current_user.has_facebook?
    @current_following_facebook_uids ||= current_user.followings.up.collect{|f|f.other_user.facebook_uid}.compact
  end  
  
  def current_ignoring_ids
    return [] unless logged_in? and current_user.ignorings_count > 0
    @current_ignoring_ids ||= current_user.followings.down.collect{|f|f.other_user_id}    
  end
  
  def current_tags
    return [] unless current_instance.is_tags?
    @current_tags ||= Rails.cache.fetch('Tag.by_endorsers_count.all') { Tag.by_endorsers_count.all }
  end

  def load_actions_to_publish
    @user_action_to_publish = flash[:user_action_to_publish] 
    flash[:user_action_to_publish]=nil
  end  
  
  def check_suspension
    if logged_in? and current_user and current_user.status == 'suspended'
      reset_session
      flash[:notice] = "This account has been suspended."
      redirect_to root_path
      nil
    end
  end
  
  # they were trying to endorse a idea, so let's go ahead and add it and take htem to their ideas page immediately
  def check_idea
    return unless logged_in? and session[:idea_id]
    @idea = Idea.find(session[:idea_id])
    @value = session[:value].to_i
    if @idea
      if @value == 1
        @idea.endorse(current_user,request,current_sub_instance,@referral)
      else
        @idea.oppose(current_user,request,current_sub_instance,@referral)
      end
    end  
    session[:idea_id] = nil
    session[:value] = nil
  end
  
  def update_loggedin_at
    return unless logged_in?
    return unless current_user.loggedin_at.nil? or Time.now > current_user.loggedin_at+30.minutes
    begin
      User.find(current_user.id).update_attribute(:loggedin_at,Time.now)
    rescue
    end
  end

  def check_blast_click
    # if they've got a ?b= code, log them in as that user
    if params[:b] and params[:b].length > 2
      @blast = Blast.find_by_code(params[:b])
      if @blast and not logged_in?
        self.current_user = @blast.user
        @blast.increment!(:clicks_count)
      end
      redirect = request.path_info.split('?').first
      redirect = "/" if not redirect
      redirect_to redirect
      return
    end
  end

  def check_referral
    if not params[:referral_id].blank?
      @referral = User.find(params[:referral_id])
    else
      @referral = nil
    end    
  end  

  def current_facebook_user_if_on_facebook

    return nil
    # ret_user = nil
    # begin
    #   ret_user = current_facebook_user
    # rescue Mogli::Client::OAuthException
    #   return nil
    # end
    # ret_user
  end

  # if they're logged in with our account, AND connected with facebook, but don't have their facebook uid added to their account yet
  def check_facebook 
    if logged_in? and current_facebook_user_if_on_facebook
      unless current_user.facebook_uid
        @user = User.find(current_user.id)
        if not @user.update_with_facebook(current_facebook_user)
          return
        end
        if not @user.activated?
          @user.activate!
        end      
        @current_user = User.find(current_user.id)
        flash.now[:notice] = tr("Your account is now synced with Facebook. In the future, to sign in, simply click the big blue Facebook button.", "controller/application", :instance_name => tr(current_instance.name,"Name from database"))
      end
    end      
  end
  
  def is_robot?
    return true if request.format == 'rss' or params[:controller] == 'pictures'
    request.user_agent =~ /\b(Baidu|Gigabot|Googlebot|libwww-perl|lwp-trivial|msnbot|SiteUptime|Slurp|WordPress|ZIBB|ZyBorg)\b/i
  end
  
  def no_facebook?
    return true
  end
  
  def bad_token
    flash[:error] = tr("Sorry, that last page already expired. Please try what you were doing again.", "controller/application")
    respond_to do |format|
      format.html { redirect_to request.referrer||'/' }
      format.js { redirect_from_facebox(request.referrer||'/') }
    end
  end

  def js_help
    JavaScriptHelper.instance
  end

  class JavaScriptHelper
    include Singleton
    include ActionView::Helpers::JavaScriptHelper
  end
end
