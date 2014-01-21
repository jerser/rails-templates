require "bundler/capistrano"
require "json"
load "deploy/assets"

set :repository, "__GIT_REPOSITORY__"
set :scm, :git
set(:branch) { current_branch }

desc "Staging server settings"
task :staging do
  server "__STAGING_SERVER__", :app, :web, :db, :primary => true

  set :user, "__STAGING_USER__"
end

desc "Production server settings"
task :production do
  server "__PRODUCTION_SERVER__", :app, :web, :db, :primary => true

  set :copy_compression, :bz2
  set :copy_via, :scp
  set :deploy_via, :copy

  set :user, "__PRODUCTION_USER__"
end

set(:application) { user.capitalize }

set(:deploy_to) { "/home/#{user}/#{application}" }
set :use_sudo, false

default_run_options[:shell] = '/bin/bash --login'
default_environment["RAILS_ENV"] = 'production'

task :symlink_database_yml do
  run "rm #{release_path}/config/database.yml"
  run "[ -d #{shared_path}/config ] || mkdir #{shared_path}/config &&  echo -e \""\
      'production:\n  adapter: postgresql\n  database: ' + user + '" > '\
      "#{shared_path}/config/database.yml"
  run "ln -sfn #{shared_path}/config/database.yml " \
      "#{release_path}/config/database.yml"
end

task :symlink_spree do
  run "rm -f #{release_path}/public/spree"
  run "[ -d #{shared_path}/spree ] || mkdir #{shared_path}/spree"
  run "ln -sfn #{shared_path}/spree " \
      "#{release_path}/public/spree"
end

task :symlink_private do
  run "rm -f #{release_path}/public/private"
  run "[ -d #{shared_path}/private ] || mkdir #{shared_path}/private"
  run "ln -sfn #{shared_path}/private " \
      "#{release_path}/public/private"
end

after "bundle:install", "symlink_database_yml"
after "bundle:install", "symlink_spree"
after "bundle:install", "symlink_private"

namespace :unicorn do
  desc "Zero-downtime restart of Unicorn"
  task :restart, except: { no_release: true } do
    if remote_file_exists? "/tmp/#{application}.pid"
      run "kill -s USR2 `cat /tmp/#{application}.pid`"
    else
      start
    end
  end

  desc "Start unicorn"
  task :start, except: { no_release: true } do
    run "cd #{current_path} ; bundle exec unicorn_rails -c config/unicorn.rb -D"
  end

  desc "Stop unicorn"
  task :stop, except: { no_release: true } do
    if remote_file_exists? "/tmp/#{application}.pid"
      run "kill -s QUIT `cat /tmp/#{application}.pid`"
    end
  end
end

after "deploy:restart", "unicorn:restart"

def remote_file_exists?(full_path)
  'true' ==  capture("if [ -e #{full_path} ]; then echo 'true'; fi").strip
end

def current_branch
  `git symbolic-ref HEAD`.gsub(/^refs\/heads\//, '').chomp
end

# AppSignal
after "deploy", "appsignal:deploy"
after "deploy:migrations", "appsignal:deploy"

namespace :appsignal do
  task :deploy do
    run "cd #{current_path} ; bundle exec appsignal notify_of_deploy " \
        "--revision=#{current_revision} " \
        "--repository=#{repository} " \
        "--user=#{ENV['USER']} " \
        "--environment=#{rails_env}"
  end
end
