class PagesController < ApplicationController
  before_filter :authenticate_admin!, :except => [:show]

  def index
    @pages = Page.all
  end

  def show
    @page = Page.find(params[:id])
  end

  def new
    @page = Page.new
  end

  def edit
    @page = Page.find(params[:id])
  end

  def create
    @page = Page.new(params[:page])

    if @page.save
      redirect_to @page
    else
      render :action => :new
    end
  end

  def update
    @page = Page.find(params[:id])

    if @page.update_attributes(params[:page])
      redirect_to @page
    else
      render :action => :edit, :status => :unprocessable_entity
    end
  end

  def destroy
    @page = Page.find(params[:id])
    @page.destroy
    redirect_to :action => :index
  end
end
