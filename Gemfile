source "https://rubygems.org"

gem "rails", ">= 3.2.16", "< 4"
gem "rails-i18n"
gem "sqlite3"

gem "rack-openid"
gem "ruby-openid"
gem "acts_as_list", "0.1.9"
gem "auto_html", "1.5.1"
gem "awesome_print"
gem "backup", :require => false
gem "capistrano", require: false, github: "capistrano/capistrano"
gem "daemons"
gem "dalli"
gem "delayed_job"
gem "delayed_job_active_record"
gem "devise", "2.1.2"
gem "exceptional"
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
gem "omniauth-idcard", "~> 0.2.1"
gem "paperclip"
gem "randumb"
gem "rmagick", require: false
gem "rvm-capistrano", require: false
gem "savon", "1.2.0"
gem "sass"
gem "sunlight"
gem "sys-filesystem"
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
  gem "thin"
  gem "better_errors"
end

group :test do
  gem "minitest"
  gem "minitest-rails"
  gem "minitest-reporters"

  # No need to depend on Guard. Whoever wants it can install it themselves
  # with their preferred Rails preloader like Spring or Zeus.
end

group :assets do
  gem "sass-rails"
  gem "uglifier"
  gem "jquery-ui-rails"
  gem "execjs"
  gem "therubyracer", "~> 0.10.2", :platforms => :ruby
end

group :production do
  gem "newrelic_rpm"
end
