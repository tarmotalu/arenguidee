class UsersController < ApplicationController
  before_filter :authenticate_user!, :except => [:show]
  before_filter :authenticate_admin!, :only => [:index]

  def index
    @users = User.all
  end

  def edit
    @user = User.find(params[:id])
    return redirect_to url_for(@user) if current_user != @user
  end

  def update
    @user = User.find(params[:id])
    return redirect_to url_for(@user) if current_user != @user

    if @user.update_attributes(user_params)
      redirect_to @user
    else
      render "edit", :status => :unprocessable_entity
    end
  end

  def show
    @user = User.find(params[:id])
    @ideas = Idea.published.own.where(:user_id => @user.id)
  end

  private
  def user_params
    allowed_params = %w[first_name last_name email bio]
    params[:user].slice(*allowed_params) if params[:user]
  end
end
