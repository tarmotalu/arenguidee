set :rvm_ruby_string, 'ruby-1.9.3-p327'
require "rvm/capistrano"
require 'bundler/capistrano'
require 'airbrake/capistrano'
require "thinking_sphinx/deploy/capistrano"
require "auto_html/capistrano"
set :whenever_command, "bundle exec whenever"
require "whenever/capistrano"

ssh_options[:forward_agent] = true
set :application, "rahvakogu_staging"
set :domain, "rahvakogu.ee"
set :scm, "git"
set :repository, "git@217.146.75.17:/var/git/social_innovation.git"

set :selected_branch, "master"
set :branch, "#{selected_branch}"
set :use_sudo, false
set :deploy_to, "/var/www/#{application}"
set :user, "www-data"
set :deploy_via, :remote_cache
set :rails_env, "staging"
# set :shared_children, shared_children + %w[config db/sphinx assets db/hourly_backup db/daily_backup db/weekly_backup]

role :app, domain
role :web, domain
role :db,  domain, :primary => true

namespace :deploy do
  task :start do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

# before 'deploy:update_code' do
#   thinking_sphinx.stop
# end

# after 'deploy:update_code' do
#   thinking_sphinx.configure
#   thinking_sphinx.rebuild
# end

after 'deploy:finalize_update' do
  run "ln -nfs #{deploy_to}/#{shared_dir}/config/* #{current_release}/config/"
  run "ln -nfs #{deploy_to}/#{shared_dir}/db/sphinx #{current_release}/db/sphinx"
  run "mkdir #{current_release}/lib/geoip"
  run "ln -nfs #{deploy_to}/#{shared_dir}/geoip/GeoIP.dat #{current_release}/lib/geoip/GeoIP.dat"
  run "ln -nfs #{deploy_to}/#{shared_dir}/assets #{current_release}/public/assets"
  run "ln -nfs #{deploy_to}/#{shared_dir}/system #{current_release}/public/system"
end

namespace :log do
  desc 'Show application logs from server'
  task :tail, :roles => :app do
    run "tail -f -n100 #{shared_path}/log/#{rails_env}.log" do |channel, stream, data|
      puts data
      break if stream == :err    
    end
  end
  
  desc "Check production log files in TextMate™"
  task :mate, :roles => :app do
    require 'tempfile'
    tmp = Tempfile.open('w')
    logs = Hash.new { |h,k| h[k] = '' }

    run "tail -n500 #{shared_path}/log/#{rails_env}.log" do |channel, stream, data|
      logs[channel[:host]] << data
      break if stream == :err
    end

    logs.each { |host, log| tmp.write("--- #{host} ---\n\n#{log}\n") }

    exec "mate -w #{tmp.path}" 
    tmp.close
  end
end

namespace :delayed_job do
  desc "Restart the delayed_job process"
  task :restart, :roles => :app do
    run "cd #{current_path} && RAILS_ENV=#{rails_env} bundle exec ruby script/delayed_job restart"
  end
end

after "deploy", "delayed_job:restart"
