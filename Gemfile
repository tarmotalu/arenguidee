source "https://rubygems.org"

gem "rails", ">= 3.2.16", "< 4"
gem "rails-i18n"

gem "acts_as_list", "0.1.9"
gem "auto_html", "1.5.1"
gem "awesome_print"
gem "daemons"
gem "delayed_job"
gem "delayed_job_active_record"
#gem "devise", "2.1.2"
gem 'devise', '3.2.2'
gem 'omniauth-idcard', '0.2.3'
gem 'omniauth-mobileid', '0.3.1'
gem "digidoc_client", "0.2.1"
#gem "omniauth-idcard", "~> 0.2.1"
#gem "omniauth-mobileid"
gem "friendly_id", "4.0.9"
gem "geoip"
gem "googlecharts"
gem "haml", ">= 3.2.0.rc.1"
gem "haml-rails"
gem "hpricot"
gem "html5shiv-rails"
gem "htmldiff"
gem "htmlentities"
gem "jquery-rails"
gem "jquery-rjs", github: "bikeexchange/jquery-rjs"
gem "kaminari"
gem "kgio"
gem "nested_form", :git => "git://github.com/ryanb/nested_form.git"
gem "nokogiri"
gem "oauth"
gem "paperclip"
gem "randumb"
gem "rmagick", require: false
gem "sqlite3"
gem "sunlight"
gem "sys-filesystem"
gem "thin"
gem "thinking-sphinx", "2.0.13"
gem "tr8n", github: "hinrik/tr8n", :branch => "social_innovation"
gem "truncate_html"
gem "whenever", :require => false
gem "will-paginate-i18n"
gem "will_paginate"
gem "workflow"

# Versions < 1.5.1 are vulnerable.
gem "omniauth-facebook", ">= 1.5.1"

group :development do
  gem "better_errors"

  # Dev-Boost reloads files as they're changed and not before a request as
  # Rails (supposedly) does and thereby speeds up pageloads.
  gem "rails-dev-boost"
  gem "mysql2"
end

group :test do
  gem "minitest"
  gem "minitest-rails"
  gem "minitest-reporters"
  gem "timecop"

  # No need to depend on Guard. Whoever wants it can install it themselves
  # with their preferred Rails preloader like Spring or Zeus.
end

group :production do
  gem "mysql2"
end

group :assets do
  gem "execjs"
  gem "jquery-ui-rails"
  gem "sass-rails"
  gem "therubyracer", "~> 0.10.2", :platforms => :ruby
  gem "uglifier"
end

group :deploy do
  gem "mina"
end
