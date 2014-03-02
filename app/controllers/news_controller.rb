class NewsController < ApplicationController
  before_filter :authenticate_admin!

  def index
    @news = News.order("date ASC").all
  end

  def new
    @news = News.new
  end

  def edit
    @news = News.find(params[:id])
  end

  def create
    @news = News.new(params[:news])

    if @news.save
      redirect_to :action => "index"
    else
      render :action => "new"
    end
  end

  def update
    @news = News.find(params[:id])

    if @news.update_attributes(params[:news])
      redirect_to :action => "index"
    else
      render :action => "edit", :status => :unprocessable_entity
    end
  end

  def destroy
    @news = News.find(params[:id])
    @news.destroy
    redirect_to :action => "index"
  end
end
