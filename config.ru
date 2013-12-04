require './controllers/home'

use Rack::Static, {
  :root => "public",
  :urls => ["/css", "/js", "/img", "/favicon.ico", "/robots.txt"],
  :cache_control => 'public'
}

use Rack::Session::Cookie, {
  :secret => ENV['SESSION_SECRET'] || 'xKU9Ybq23jafjhh',
  :httponly => true,
  :secure => (ENV['RACK_ENV'] == 'production'),
  #:expire_after => 24 * 3600,
}

map '/' do
  run HomeController
end
