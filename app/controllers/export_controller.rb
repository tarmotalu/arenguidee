class ExportController < ApplicationController

  before_filter :admin_required

  def index
    require 'csv'
    @ideas = Idea.published.includes([:points, :endorsements]).order(:id)
    @ideas.sort!{|x| x.all_for.count }
    @ideas.reverse!
    @outfile = "ettepanekut_" + Time.now.strftime("%m-%d-%Y") + ".csv"
    csv_data = CSV.generate do |csv|
      csv << [
        "id",
        "Type",
        "Name",
        "Content",
        "Toetan",
        "Olen Vastu",
      ]
      @ideas.each do |idea|
        csv << [
          idea.id,
          idea.category.name,
          idea.name,
          idea.description,
          idea.all_for.count,
          idea.all_against.count
        ]
        idea.points.published.sort{|x, y| y.value <=> x.value}.each do |point|
          csv << [
            idea.id,
            "Argument",
            point.name,
            point.content,
            point.value == 1 ? point.value : 0,
            point.value == -1 ? point.value : 0
          ]
        end
      end
    end
    send_data csv_data,
      :type => 'text/csv; charset=iso-8859-1; header=present',
      :disposition => "attachment; filename=#{@outfile}"
    flash[:notice] = "Export complete!"
  end

end