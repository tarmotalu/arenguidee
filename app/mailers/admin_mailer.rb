class AdminMailer < ActionMailer::Base
  default :from => Arenguidee.config["admin_email"]
  default :to => Arenguidee.config["admin_email"]

  def new_idea(idea)
    @idea = idea
    mail :subject => "[Arenguidee] Uus idee: #{idea.name}"
  end
end
