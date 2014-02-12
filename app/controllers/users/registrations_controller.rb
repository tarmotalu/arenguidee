class Users::RegistrationsController < Devise::RegistrationsController
  skip_before_filter :verify_authenticity_token, :only => [:failure]
  before_filter :development_id, :only => :failure if Rails.env.development?

  prepend_before_filter :only => [:facebook, :failure] do
    request.env["devise.skip_timeout"] = true
  end

  def idcard
    omniauthenticate(request.env['omniauth.auth'])
  end

  def failure
    session[:omniauth] = nil
    session[:selected_tab] = params[:selected_tab] if params[:selected_tab]
    error = request.env["omniauth.error"]
    error_type = request.env["omniauth.error.type"]
    logger.error error.try(:inspect)
    redirect = stored_location_for(:user) || root_path
    if error_type.present?
      flash[:alert] = t(error_type, :scope => "mobile_id.fault")
    elsif error.is_a?(Errno::ENETUNREACH)
      flash[:alert] = t("sessions.network.no_connection")
    else
      flash[:alert] = t("sessions.new.invalid_credentials")
    end

    respond_to do |format|
      format.html {  redirect_to redirect }
      format.js { render :json => {:redirect => root_path} }
    end
  end

  private
  def build_resource(*args)
    super

    if session[:omniauth]
      @user.apply_omniauth(session[:omniauth])
      @user.valid?
    end
  end

  def development_id
    ActiveRecord::IdentityMap.without do
      omniauthenticate('user_info' => {
        'personal_code' => '38004100067',
        'first_name' => 'John',
        'last_name' => 'Fail'
      })
    end
  end

  def omniauthenticate(omniauth)
    logger.info omniauth.inspect
    session[:omniauth] = nil
    notice, alert, redirect = nil, nil, nil
    provider = omniauth['provider'] if omniauth
    uid = omniauth['uid'] if omniauth

    if omniauth
      @user = User.find_by_login(omniauth['user_info']['personal_code'])

      if @user
        notice = t('devise.sessions.signed_in')
        redirect = stored_location_for(:user) || '/'
        sign_in(:user, @user)
      else
        # Authentication was successful, but user is not registered in the
        # system
        session[:omniauth] = omniauth
        alert = t('sessions.new.not_registered', :username => omniauth['user_info']['name'])
        redirect = new_user_registration_url
      end
    else
      alert = t('sessions.new.invalid_user_info')
      redirect = root_path
    end

    respond_to do |format|
      format.html do
        flash[:alert] = alert if alert
        flash[:notice] = notice if notice
        redirect_to redirect, :alert => flash[:alert]
      end

      format.js do
        render :json => {
          :alert => alert, :notice => notice, :redirect => redirect
        }
      end
    end
  end
end
