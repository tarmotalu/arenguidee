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

  fb_app_id = Rahvakogu.config["facebook_app_id"]
  fb_app_secret = Rahvakogu.config["facebook_app_secret"]
  fb_opts = {:scope => "email,user_about_me"}
  config.omniauth :facebook, fb_app_id, fb_app_secret, fb_opts

  config.omniauth :idcard
end

# Nginx passes $ssl_client_cert with indented lines which breaks
# OpenSSL::X509::Certificate. Strip them.
require "omniauth/strategies/idcard"

class OmniAuth::Strategies::Idcard
  def parse_client_certificate_with_strip_lines(data)
    parse_client_certificate_without_strip_lines data.lines.map(&:strip).join $/
  end
  alias_method_chain :parse_client_certificate, :strip_lines
end
