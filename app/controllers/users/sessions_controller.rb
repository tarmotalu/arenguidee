class Users::SessionsController < Devise::SessionsController
  skip_before_filter :check_idea
  skip_before_filter :check_referral
  skip_before_filter :check_suspension
  skip_before_filter :update_loggedin_at
  skip_before_filter :check_blast_click

  skip_before_filter :verify_authenticity_token, :only => [:failure]

  prepend_before_filter :only => [:idcard, :facebook, :failure] do
    request.env["devise.skip_timeout"] = true
  end

  def facebook
    info = request.env["omniauth.auth"]
    user = User.where(:facebook_uid => info["uid"]).first || User.new
    return sign_in_and_redirect(user) if user.persisted?

    # Setting login just for validations for now.
    user.login = SecureRandom.uuid
    user.facebook_uid = info["uid"]
    user.email = info["info"]["email"]
    user.first_name = info["info"]["first_name"]
    user.last_name = info["info"]["last_name"]

    if user.save
      sign_in_and_redirect user
    else
      flash.alert = user.errors.full_messages.join("\n")
      redirect_to new_user_session_path
    end
  end

  def idcard
    info = request.env["omniauth.auth"]
    user = User.where(:login => info["uid"]).first || User.new
    return sign_in_and_redirect(user) if user.persisted?

    # NOTE: Omniauth::Idcard returns extra info in the "user_info" property
    # while the standard seems to be "info".
    user.login = info["uid"]
    user.first_name = info["user_info"]["first_name"]
    user.last_name = info["user_info"]["last_name"]

    if user.save
      sign_in_and_redirect user
    else
      flash.alert = user.errors.full_messages.join("\n")
      redirect_to new_user_session_path
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

    redirect_to new_user_session_path
  end
end
