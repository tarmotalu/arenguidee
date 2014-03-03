class Users::SessionsController < Devise::SessionsController
  skip_before_filter :check_idea
  skip_before_filter :check_referral
  skip_before_filter :check_suspension
  skip_before_filter :update_loggedin_at
  skip_before_filter :check_blast_click

  prepend_before_filter :only => [:facebook, :idcard, :mobileid, :failure] do
    request.env["devise.skip_timeout"] = true
  end

  def new
    @phone = params[:phone]
  end

  def facebook
    info = request.env["omniauth.auth"]
    user = User.where(:facebook_uid => info["uid"]).first || User.new({
      :facebook_uid => info["uid"],
      :email => info["info"]["email"],
      :first_name => info["info"]["first_name"] || "",
      :last_name => info["info"]["last_name"] || ""
    })

    if user.persisted? or user.save
      sign_in_and_redirect user
    else
      flash.alert = user.errors.full_messages.join("\n")
      redirect_to new_user_session_path
    end
  end

  def idcard
    info = request.env["omniauth.auth"]
    user = User.where(:login => info["uid"]).first || User.new({
      # NOTE: Omniauth::Idcard returns extra info in the "user_info" property
      # while the standard seems to be "info".
      :login => info["uid"],
      :first_name => (info["user_info"]["first_name"] || "").mb_chars.titleize,
      :last_name => (info["user_info"]["last_name"] || "").mb_chars.titleize
    })

    if user.persisted? or user.save
      sign_in_and_redirect user
    else
      flash.alert = user.errors.full_messages.join("\n")
      redirect_to new_user_session_path
    end
  end

  def mobileid
    return mobileid_read_pin if request.env["omniauth.phase"] != "authenticated"
    info = encryptor.decrypt_and_verify(params[:info])

    valid = true
    valid = valid && info["read_pin"]["session_code"] == params[:session_code]
    valid = valid && Time.now - info["time"] < 5.minutes
    raise InvalidInfo unless valid

    user = User.where(:login => info["uid"]).first || User.new({
      :login => info["uid"],
      :first_name => (info["user_info"]["first_name"] || "").mb_chars.titleize,
      :last_name => (info["user_info"]["last_name"] || "").mb_chars.titleize
    })

    if user.persisted? or user.save
      sign_in user
      render :js => %(window.location = "#{root_path}")
    else
      flash.alert = user.errors.full_messages.join("\n")
      render :js => %(window.location = "#{new_user_session_path}")
    end
  end

  def failure
    type = request.env["omniauth.error.type"]

    if type && request.env["omniauth.strategy"].name == "mobileid"
      flash.alert = t("users.sessions.mobileid.#{type}")
    elsif type
      flash.alert = t("users.sessions.#{type}")
    elsif request.env["omniauth.error"].is_a?(Errno::ENETUNREACH)
      flash.alert = t("users.sessions.no_network_connection")
    end

    args = {:phone => params[:phone]} if params[:phone].present?
    path = new_user_session_path(args)
    respond_to do |format|
      format.html { redirect_to path }
      format.js { render :js => %(window.location = "#{path}") }
    end
  end

  private
  def mobileid_read_pin
    # Personal info is only given at the start of the authentication process.
    if info = request.env["omniauth.auth"]
      @session_code = info["read_pin"]["session_code"]
      @challenge_id = info["read_pin"]["challenge_id"]

      info = info.to_hash.slice(*%w[uid user_info read_pin])
      info["time"] = Time.now
      @info = encryptor.encrypt_and_sign(info)
    end

    respond_to do |format|
      format.html
      format.js { render :nothing => true }
    end
  end

  def encryptor
    @encryptor ||= begin
      ActiveSupport::MessageEncryptor.new(Rails.configuration.secret_token)
    end
  end

  class InvalidInfo < StandardError; end
end
