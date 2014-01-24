# Only use Postgresql
gsub_file 'Gemfile', /^gem\s+["']sqlite3["'].*$/, ''
gem 'pg'

# Use Slim for templates instead of erb
gem 'slim-rails'

# Use Bourboun and Neat for frontend
gem 'bourbon'
gem 'neat'

# Set the Javascript engines for MRI and JRuby
gem 'therubyracer', platforms: :ruby
gem 'therubyrhino', platforms: :ruby

# User Opal instead of CoffeeScript
gem 'opal-rails'
gsub_file 'Gemfile', /^gem\s+["']coffee-rails["'].*$/, ''

gem_group :production do
  gem 'unicorn'
  gem 'appsignal'
end

gem_group :development do
  gem 'capistrano', '~> 2.5.14'
end

# Remove all comments and empty lines
gsub_file 'Gemfile', /^#.*$/, ''
gsub_file 'Gemfile', /\n+/, "\n"

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

# Replace application.css with application.css.scss for Bourbon and Neat
run 'rm app/assets/stylesheets/application.css'
run 'echo -e "@import \"bourbon\";\n@import \"grid-settings\";\n@import \"neat\";" > app/assets/stylesheets/application.css.scss'
run 'echo -e "@import \"neat-helpers\";\n" > app/assets/stylesheets/_grid-settings.scss'

# Replace application.js with application.js.rb for Opal
run 'rm app/assets/javascripts/application.js'
run 'echo -e "//= require opal\n//= require opal_ujs\n//= require turbolinks\n//= require_tree ." > app/assets/javascripts/application.js.rb'

# Replace application.html.erb with application.html.slim
run 'rm app/views/layouts/application.html.erb'
run "echo -e \"doctype html\nhtml\n  head\n    title #{app_name.humanize}\n   \"\
             \"== stylesheet_link_tag \\\"application\\\", media: \\\"all\\\", \\\"data-turbolinks-track\\\" => true\n   \"\
             \"== javascript_include_tag \\\"application\\\", \\\"data-turbolinks-track\\\" => true\n   \"\
             \"== csrf_meta_tags\n\n  body\n    == yield\" > app/views/layouts/application.html.slim"

run 'rm README.rdoc'

run 'echo "ruby-2.0" > .ruby-version'

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
  run 'echo -e "load \'deploy\'\nload \'config/deploy\'" > Capfile'
end

git :init
git add: '.'
git commit: "-a -m 'Initial commit'"
