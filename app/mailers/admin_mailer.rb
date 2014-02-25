class AdminMailer < ActionMailer::Base
  default :from => Rahvakogu.config["admin_email"]
  default :to => Rahvakogu.config["admin_email"]

  def new_idea(idea)
    @idea = idea
    mail :subject => "[Arenguidee] Uus idee: #{idea.name}"
  end
end
