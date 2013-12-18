require './init'
require './models'
require './controllers'

use Rack::Static, {
  :root => "public",
  :urls => ["/fonts", "/css", "/js", "/img", "/favicon.ico", "/robots.txt"],
  :cache_control => 'public'
}

use Rack::Session::Cookie, {
  :secret => ENV['SESSION_SECRET'] || 'xKU9Ybq23jafjhh',
  :httponly => true,
  :secure => (ENV['RACK_ENV'] == 'production'),
  #:expire_after => 24 * 3600,
}

map '/admin' do
  use Rack::Auth::Basic do |u, p|
    [u, p] == ['avnsp', 'One does not simply walk into mordor!']
  end
  run AdminController
end

#use AuthController

map '/' do
  run HomeController
end

map '/event' do
  run EventController
end

map '/photo' do
  run PhotoController
end
