spree_version = '2-1-stable'

gem_group :production do
  gem 'unicorn'
  gem 'appsignal'
end
gem_group :development do
  gem 'capistrano', '~> 2.5.14'
end
gem 'spree', github: 'spree/spree', branch: spree_version
gem 'spree_auth_devise', github: 'spree/spree_auth_devise', branch: spree_version
gem 'spree_i18n', github: 'spree/spree_i18n', branch: spree_version

gem 'pg'
gsub_file 'Gemfile', /^gem\s+["']sqlite3["'].*$/, ''

if yes? 'Europabank integration? (y/N)'
  gem 'active_merchant-europabank', github: 'jerser/active_merchant-europabank'
  gem 'spree_europabank', github: 'jerser/spree_europabank'
end

run 'bundle install'

run 'rm config/database.yml'
file 'config/database.yml', <<-CONFIG
  development:
    adapter: postgresql
    database: #{@app_name}

  test:
    adapter: postgresql
    database: #{@app_name}_test
CONFIG

run "createdb #{@app_name}"
run "createdb #{@app_name}_test"

generate('spree:install', '--auto-accept')

run 'rm README.rdoc'

inside 'config' do
  run 'wget https://raw.github.com/jerser/rails-templates/master/config/spree_deploy.rb'\
      ' -O deploy.rb'
  gsub_file 'deploy.rb', /__GIT_REPOSITORY__/, ask('Git repository?')
  gsub_file 'deploy.rb', /__STAGING_SERVER__/, ask('Staging server?')
  gsub_file 'deploy.rb', /__STAGING_USER__/, ask('Staging user?')
  gsub_file 'deploy.rb', /__PRODUCTION_SERVER__/, ask('Production server?')
  gsub_file 'deploy.rb', /__PRODUCTION_USER__/, ask('Production user?')
  run 'wget https://raw.github.com/jerser/rails-templates/master/config/unicorn.rb'\
      ' -O unicorn.rb'
end
run 'echo -e "load \'deploy\'\nload \'config/deploy\'" > Capfile'

git :init
git add: '.'
git commit: "-a -m 'Initial commit'"
