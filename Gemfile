source 'http://rubygems.org'
ruby '2.1.2'
gem 'rails'

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

gem 'bson'
gem 'bson_ext'
gem 'mongoid'
gem 'thin'
gem 'haml-rails'
gem 'simple_form'
gem 'redcarpet'
gem 'omniauth'
gem 'omniauth-github'
# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails'
  gem 'uglifier'
  gem 'haml'
end

group :production do 
	gem 'newrelic_rpm'
end
gem 'jquery-rails'
group :development do 
#  gem 'ruby-debug19', :require => 'ruby-debug'
  gem 'therubyracer'
end
# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

group :test do
  # Pretty printed test output
  gem 'turn', :require => false
end
