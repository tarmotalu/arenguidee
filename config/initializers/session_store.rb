# Be sure to restart your server when you modify this file.

if Rails.env.development?
  Rahvakogu::Application.config.session_store :cookie_store, key: Rails.application.config.database_configuration[Rails.env]["session_key"]
elsif Rails.env.staging?
  Rahvakogu::Application.config.session_store ActionDispatch::Session::CacheStore, :expire_after => 20.minutes
else
  Rahvakogu::Application.config.session_store :cookie_store, key: Rails.application.config.database_configuration[Rails.env]["session_key"],  :domain => ".#{Instance.last.domain_name}"
end

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Rahvakogu::Application.config.session_store :active_record_store
