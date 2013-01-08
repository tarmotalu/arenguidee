set :rvm_ruby_string, 'ruby-1.9.3-p327'
require "rvm/capistrano"
require 'bundler/capistrano'
# require 'airbrake/capistrano'
require "thinking_sphinx/deploy/capistrano"
require "auto_html/capistrano"
set :whenever_command, "bundle exec whenever"
require "whenever/capistrano"
# load 'deploy/assets'


task :staging do
  set :deploy_to, "/var/www/#{application}_staging"
  set :rails_env, "staging"
  after 'deploy:finalize_update' do
    run "cp #{deploy_to}/#{shared_dir}/htaccess #{current_release}/public/.htaccess"
    run "ln -nfs /var/www/rahvakogu_production/system/users/buddy_icons #{current_release}/public/system/users/buddy_icons"
  end
end



set :application, "rahvakogu"
ssh_options[:forward_agent] = true

set :domain, "rahvakogu.ee"
set :scm, "git"
set :repository, "git@217.146.75.17:/var/git/social_innovation.git"

set :selected_branch, "master"
set :branch, "#{selected_branch}"
set :use_sudo, false
set :deploy_to, "/var/www/#{application}_#{rails_env}"
set :user, "www-data"
set :deploy_via, :remote_cache

# set :shared_children, shared_children + %w[config db/sphinx assets db/hourly_backup db/daily_backup db/weekly_backup]

role :app, domain
role :web, domain
role :db,  domain, :primary => true

namespace :deploy do
  namespace :assets do
    task :precompile, :roles => :web, :except => { :no_release => true } do
      from = source.next_revision(current_revision)
      if capture("cd #{latest_release} && #{source.local.log(from)} vendor/assets/ app/assets/ | wc -l").to_i > 0
        run %Q{cd #{latest_release} && #{rake} RAILS_ENV=#{rails_env} #{asset_env} assets:precompile}
      else
        logger.info "Skipping asset pre-compilation because there were no asset changes"
      end
    end
  end
  task :start do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

before 'deploy:update_code' do
  thinking_sphinx.stop
end

after 'deploy:update_code' do
  thinking_sphinx.configure
  thinking_sphinx.rebuild
end

after 'deploy:finalize_update' do
  run "ln -nfs #{deploy_to}/#{shared_dir}/config/* #{current_release}/config/"
  run "ln -nfs #{deploy_to}/#{shared_dir}/db/sphinx #{current_release}/db/sphinx"
  run "mkdir #{current_release}/lib/geoip"
  run "ln -nfs #{deploy_to}/#{shared_dir}/geoip/GeoIP.dat #{current_release}/lib/geoip/GeoIP.dat"
  run "ln -nfs #{deploy_to}/#{shared_dir}/assets #{current_release}/public/assets"
  run "ln -nfs #{deploy_to}/#{shared_dir}/system #{current_release}/public/system"
end

# namespace :assets do
#   desc "Precompile assets locally and then rsync to app servers"
#   task :precompile, :only => { :primary => true } do
#     run_locally "mkdir -p public/__assets; mv public/__assets public/assets;"
#     run_locally "bundle exec rake assets:clean_expired; bundle exec rake assets:precompile;"
#     servers = find_servers :roles => [:app], :except => { :no_release => true }
#     servers.each do |server|
#       run_locally "rsync -av ./public/assets/ #{user}@#{server}:#{current_path}/public/assets/;"
#     end
#     run_locally "mv public/assets public/__assets"
#   end
# end


namespace :log do
  desc 'Show application logs from server'
  task :tail, :roles => :app do
    run "tail -f -n100 #{shared_path}/log/#{rails_env}.log #{shared_path}/log/webservices.log" do |channel, stream, data|
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

after "deploy", "deploy:migrate"
after "deploy", "delayed_job:restart"
