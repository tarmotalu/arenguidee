# Be sure to restart your server when you modify this file.

if Rails.env.development?
  Rahvakogu::Application.config.session_store :cookie_store, key: Rails.application.config.database_configuration[Rails.env]["session_key"]
else
  Rahvakogu::Application.config.session_store :cookie_store, key: Rails.application.config.database_configuration[Rails.env]["session_key"],  :domain => ".#{Instance.last.domain_name}"
end
