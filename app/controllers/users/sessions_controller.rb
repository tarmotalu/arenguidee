class Users::SessionsController < ApplicationController
  skip_before_filter :check_idea
  skip_before_filter :check_referral
  skip_before_filter :check_suspension
  skip_before_filter :update_loggedin_at
  skip_before_filter :check_blast_click

  skip_before_filter :verify_authenticity_token, :only => [:failure]

  prepend_before_filter :only => [:idcard, :facebook, :failure] do
    request.env["devise.skip_timeout"] = true
  end

  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    Thread.current[:current_user] = nil
    flash[:notice] = tr("Logged out. Please come again soon.", "controller/sessions")
    redirect_to("/")
  end

  def idcard
    # Is this ever the case where omniauth.auth is nil, yet this action is
    # called?
    if !request.env["omniauth.auth"]
      redirect_to root_path, :alert => t("sessions.new.invalid_user_info")
      return
    end

    info = omniauth["user_info"]

    if user = User.find_by_login(info["personal_code"])
      flash.notice = t("devise.sessions.signed_in")
      sign_in_and_redirect user
    else
      # Authentication was successful, but user is not registered in the system.
      session[:omniauth] = request.env["omniauth.auth"]
      flash.alert = t("sessions.new.not_registered", :username => info["name"])
      redirect_to new_user_registration_url
    end
  end

  def facebook
    info = request.env["omniauth.auth"]
    user = User.where(:facebook_uid => info["uid"]).first || User.new
    return sign_in_and_redirect(user) if user.persisted?

    user = User.new
    user.facebook_uid = info["uid"]
    user.email = info["info"]["email"]
    user.first_name = info["info"]["first_name"]
    user.last_name = info["info"]["last_name"]

    # Setting login to satisfy validations, but it could clash with the ID card
    # auth which assumes login is for the personal identity number.
    user.login = info["uid"]

    if user.save
      sign_in_and_redirect user
    else
      flash.alert = user.errors.full_messages.join("\n")
      redirect_to after_sign_in_path_for(:user)
    end
  end

  def failure
    if type = request.env["omniauth.error.type"]
      flash.notice = t("users.sessions.#{type}")
    elsif request.env["omniauth.error"].is_a?(Errno::ENETUNREACH)
      flash.alert = t("users.sessions.no_network_connection")
    else
      flash.alert = t("users.sessions.invalid_credentials")
    end

    redirect_to after_sign_in_path_for(:user)
  end
end
