class CategoriesController < ApplicationController
  before_filter :admin_required

  def index
    @categories = Category.sorted.all
  end

  def new
    @category = Category.new
  end

  def edit
    @category = Category.unscoped.find(params[:id])
  end

  def create
    @category = Category.new(params[:category])

    if @category.save
      redirect_to :action => :index
    else
      render :action => :new
    end
  end

  def update
    @category = Category.find(params[:id])

    if @category.update_attributes(params[:category])
      redirect_to :action => :index
    else
      render :action => :edit
    end
  end

  def destroy
    @category = Category.find(params[:id])
    @category.destroy
    redirect_to :action => :index
  end
end
