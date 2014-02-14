Devise.setup do |config|
  require 'devise/orm/active_record'
  config.mailer_sender = "please-change-me@config-initializers-devise.com"

  config.reset_password_within = 6.hours
  config.case_insensitive_keys = [:email]
  config.authentication_keys = [ :email ]

  # For bcrypt, this is the cost for hashing the password and defaults to 10.
  # If using other encryptors, it sets how many times you want the password
  # re-encrypted.
  config.stretches = 10

  # Setup a pepper to generate the encrypted password.
  config.pepper = Rahvakogu.config["pepper"]

  config.remember_for = 1.day
  # If true, extends the user's remember period when remembered via cookie.
  config.extend_remember_period = true

  fb_app_id = Rahvakogu.config["facebook_app_id"]
  fb_app_secret = Rahvakogu.config["facebook_app_secret"]
  fb_opts = {:scope => "email,user_about_me"}
  config.omniauth :facebook, fb_app_id, fb_app_secret, fb_opts

  config.omniauth :idcard
end
