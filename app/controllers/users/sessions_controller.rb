class Users::SessionsController < ApplicationController
  skip_before_filter :check_idea
  skip_before_filter :check_referral
  skip_before_filter :check_suspension
  skip_before_filter :update_loggedin_at
  skip_before_filter :check_blast_click

  def new
    redirect_to '/users/auth/idcard'
  end

  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    Thread.current[:current_user] = nil
    flash[:notice] = tr("Logged out. Please come again soon.", "controller/sessions")
    redirect_to('/')
  end
end
