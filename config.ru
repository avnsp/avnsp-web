require 'bundler/setup'
require './init'
require './models'
require './controllers'
require 'rack/ssl-enforcer'

use Rack::SslEnforcer, :hsts => true if ENV['RACK_ENV'] == 'production'

use Rack::Static, {
  :root => "public",
  :urls => ["/fonts", "/css", "/js", "/img", "/favicon.ico", "/robots.txt"],
  :cache_control => 'public'
}

use Rack::Session::Cookie, {
  :secret => ENV['SESSION_SECRET'] || 'xKU9Ybq23jafjhh',
  :httponly => true,
  :secure => (ENV['RACK_ENV'] == 'production'),
  :expire_after => 24 * 3600 * 30,
}

use AuthController

map '/' do
  run HomeController
end

map '/party' do
  run PartyController
end

map '/photo' do
  run PhotoController
end
