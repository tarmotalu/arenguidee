class PagecommentsController < ApplicationController
  before_filter :admin_required

  def hide_comment
    @page_comment = Pagecomment.find(params[:id])
    @page_comment.hidden = true
    @page_comment.save!
    redirect_to @page_comment.page
  end
    
end