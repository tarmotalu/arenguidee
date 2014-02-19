class EndorsementsController < ApplicationController
  before_filter :authenticate_user!, :except => :index

  def index
    @endorsements = Endorsement.active_and_inactive.by_recently_created(:include => [:user,:idea]).paginate :page => params[:page], :per_page => params[:per_page]
    respond_to do |format|
      format.html { redirect_to minu_ideas_url }
      format.xml { render :xml => @endorsements.to_xml(:include => [:user, :idea], :except => NB_CONFIG['api_exclude_fields']) }
      format.json { render :json => @endorsements.to_json(:include => [:user, :idea], :except => NB_CONFIG['api_exclude_fields']) }
    end
  end
  
  def edit
    @endorsement = current_user.endorsements.find(params[:id])
    respond_to do |format|
      format.js {
        render :update do |page|
          if params[:region] == 'idea_left'
            page.replace_html 'idea_' + @endorsement.idea.id.to_s + '_position', render(:partial => "endorsements/position_form", :locals => {:endorsement => @endorsement})
            page['endorsement_' + @endorsement.id.to_s + "_position_edit"].focus
          elsif params[:region] == 'yours'
            page.replace_html 'endorsement_' + @endorsement.id.to_s, render(:partial => "endorsements/row_form", :locals => {:endorsement => @endorsement})
            page['endorsement_' + @endorsement.id.to_s + "_row_edit"].focus
          end
        end        
      }
    end
  end
  
  def update
    @endorsement = current_user.endorsements.find(params[:id])
    return if params[:endorsement][:position].to_i < 1  # if they didn't put a number in, don't do anything
    if @endorsement.insert_at(params[:endorsement][:position]) 
      respond_to do |format|
        format.js {
          render :update do |page|
            if params[:region] == 'idea_left'
              page.replace_html 'idea_' + @endorsement.idea.id.to_s + "_position",render(:partial => "endorsements/position", :locals => {:endorsement => @endorsement})
            elsif params[:region] == 'yours'
            end
            #page.replace_html 'your_ideas_container', :partial => "ideas/yours"
          end
        }
      end
    end
  end
  
  def destroy
    endorsements = current_user.admin? ? Endorsement : current_user.endorsements
    endorsement = endorsements.find(params[:id])
    endorsement.destroy

    # Don't set @endorsement as it's no longer active.
    @idea = endorsement.idea

    respond_to do |format|
      format.js { render :partial => "buttons" }
    end
  end
end
