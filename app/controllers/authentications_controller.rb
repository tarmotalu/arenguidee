# -*- encoding : utf-8 -*-
class AuthenticationsController < Devise::OmniauthCallbacksController
  skip_before_filter :verify_authenticity_token, :only => [:failure]
  before_filter :development_sign, :only => [:failure]
  
  def idcard
    authenticate_once(request.env['omniauth.auth'])
  end

  def mobileid
    if request.env['omniauth.phase'] == 'authenticated'
      omniauth = session[:omniauth].try(:dup)
      authenticate_once(omniauth)
    else
      session[:omniauth] = request.env['omniauth.auth'].except('extra') if request.env['omniauth.auth']
      @session_code = session[:omniauth]['read_pin']['session_code']
      @challenge_id = session[:omniauth]['read_pin']['challenge_id']

      respond_to do |format|
        format.html { render 'mobileid_readpin' }
        format.js do
          phase = request.env['omniauth.phase']
          render :json => {:phase => phase, :message => 'Sõnum on saadetud teie telefonile. Palun kontrollige koodi!'} # todo: add tr8n translation here
        end
      end
    end
  end

  def failure
    session[:omniauth] = nil
    session[:selected_tab] = params[:selected_tab] if params[:selected_tab]
    error = request.env["omniauth.error"]
    error_type = request.env["omniauth.error.type"]
    logger.error error.try(:inspect)
    
    if error_type.present?
      flash[:alert] = t(error_type, :scope => "mobile_id.fault")
    elsif error.is_a?(Errno::ENETUNREACH)
      flash[:alert] = t("sessions.network.no_connection")
    else
      flash[:alert] = t("sessions.new.invalid_credentials")
    end

    respond_to do |format|
      format.html { redirect_to new_session_path }
      format.js { render :json => {:redirect => new_session_path} }
    end
  end

  protected

  def development_sign
    
    return unless Rails.env.development?
    ActiveRecord::IdentityMap.without do
      logger.warn('ssd')
      authenticate_once('user_info' => {'personal_code' => '38004100067', 'first_name' => 'John William', 'last_name' => 'Fail'})
    end
  end

  def authenticate_once(omniauth = request.env["omniauth.auth"])
    logger.info omniauth.inspect
    session[:omniauth] = nil
    notice, alert, redirect = nil, nil, nil
    provider = omniauth['provider'] if omniauth
    uid = omniauth['uid'] if omniauth

    if omniauth
      @user = User.find_by_login(omniauth['user_info']['personal_code'])
      
      if @user
        notice = t('devise.sessions.signed_in')
        redirect = stored_location_for(:user) || root_path
        sign_in(:user, @user)        
      else # Authentication was successful, but user is not registered in the system
        session[:omniauth] = omniauth
        alert = t('sessions.new.not_registered', :username => omniauth['user_info']['name'])
        redirect = new_user_registration_url
      end
    else
      alert = t('sessions.new.invalid_user_info')
      redirect = new_session_path
    end

  respond_to do |format|
    format.html do
      flash[:alert] = alert if alert
      flash[:notice] = notice if notice
      redirect_to redirect, :alert => flash[:alert]
    end
    format.js do
      render :json => {:alert => alert, :notice => notice, :redirect => redirect}
    end
    end
  end
end
