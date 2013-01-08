class SearchesController < ApplicationController
  
  def index
    Rails.logger.info("Category Name #{params[:category_name]} CRC #{params[:category_name].to_crc32}") if params[:cached_issue_list]
    @page_title = tr("Search {instance_name} ideas", "controller/searches", :instance_name => tr(current_instance.name,"Name from database"))
    if params[:q]
      @query = params[:q]
      @page_title = tr("Search for '{query}'", "controller/searches", :instance_name => tr(current_instance.name,"Name from database"), :query => @query)
      begin
        if params[:global]
          @facets = ThinkingSphinx.facets @query, :all_facets => true, :populate => true, :star => true, :page => params[:page]
        else
          @facets = ThinkingSphinx.facets @query, :all_facets => true, :populate => true,  :star => true, :page => params[:page]
        end
      rescue

        flash[:error] = tr("We're sorry, the search engine is temporary unavailable. Please try again in a few moments", "search")

      end        
      if params[:category_name]
        @search_results = @facets.for(:category_name=>params[:category_name])
      elsif params[:class]
        @search_results = @facets.for(:class=>params[:class].to_s)
      else
        begin
          if params[:global]
            @search_results = ThinkingSphinx.search @query, :order => :updated_at, :populate => true, :sort_mode => :desc, :star => true, :retry_stale => true, :page => params[:page]
          else
            @search_results = ThinkingSphinx.search @query, :order => :updated_at, :populate => true, :sort_mode => :desc,  :star => true, :retry_stale => true, :page => params[:page]
          end
        rescue 
          flash[:error] = tr("We're sorry, the search engine is temporary unavailable. Please try again in a few moments", "search")
        end
      end
    end
    logger.warn(@search_results.inspect)
    respond_to do |format|
      format.html
      format.xml { render :xml => @ideas.to_xml(:except => [:user_agent,:ip_address,:referrer]) }
      format.json { render :json => @ideas.to_json(:except => [:user_agent,:ip_address,:referrer]) }
    end
  end

  #TODO: We need a new method here for handling the search
end
