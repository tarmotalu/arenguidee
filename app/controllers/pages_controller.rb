class PagesController < ApplicationController
  before_filter :authenticate_user!, :only => [:add_comment]
  before_filter :admin_required, :except => [:show, :add_comment]

  def add_comment
    @page = Page.find(params[:id])
    comment = Pagecomment.new(params[:pagecomment])
    comment.user_id = current_user.id
    @page.pagecomments << comment

    if @page.save
      flash[:notice] = 'Sinu kommentaar on postitatud.'
    else 
      flash[:error] = 'Sinu kommentaari postitamisega tekkis probleem. Proovi uuesti lehte laadida.'
    end
    respond_to do |format|
      format.html { redirect_to @page }
    end
  end

  # GET /pages
  # GET /pages.xml
  def index
    if params[:default]
      @pages = Page.unscoped.where("sub_instance_id IS NULL").all
    else
      @pages = Page.all
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @pages }
    end
  end

  # GET /pages/1
  # GET /pages/1.xml
  def show
    @page = Page.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @page }
    end
  end

  # GET /pages/new
  # GET /pages/new.xml
  def new
    @page = Page.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @page }
    end
  end

  # GET /pages/1/edit
  def edit
    @page = Page.unscoped.find(params[:id])
  end

  # POST /pages
  # POST /pages.xml
  def create
    @page = Page.new(params[:page])

    respond_to do |format|
      if @page.save
        format.html { redirect_to(@page, :notice => 'Page was successfully created.') }
        format.xml  { render :xml => @page, :status => :created, :location => @page }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /pages/1
  # PUT /pages/1.xml
  def update
    @page = Page.unscoped.find(params[:id])

    respond_to do |format|
      if @page.update_attributes(params[:page])
        format.html { redirect_to(@page, :notice => 'Page was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @page.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /pages/1
  # DELETE /pages/1.xml
  def destroy
    @page = Page.unscoped.find(params[:id])
    @page.destroy

    respond_to do |format|
      format.html { redirect_to(pages_url) }
      format.xml  { head :ok }
    end
  end
end