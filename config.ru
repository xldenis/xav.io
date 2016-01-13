
require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'serve'
require 'serve/rack'

# The project root directory
root = ::File.dirname(__FILE__)

require 'sass'
require 'sass/plugin/rack'
require 'compass'

Compass.add_project_configuration(root + '/compass.config')
Compass.configure_sass_plugin!

use Sass::Plugin::Rack  # Sass Middleware

# Other Rack Middleware
use Rack::ShowStatus      # Nice looking 404s and other messages
use Rack::ShowExceptions  # Nice looking errors

# Use Rack::TryStatic to attempt to load files from public first
require 'rack/contrib/try_static'
use Rack::TryStatic, :root => (root + '/public'), :urls => %w(/), :try => %w(.html index.html /index.html)

# Use Rack::Cascade and Rack::Directory on other platforms for static assets
run Rack::Cascade.new([
  Serve::RackAdapter.new(root + '/views'),
  Rack::Directory.new(root + '/public')
])

