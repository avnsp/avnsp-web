require 'bundler/setup'
require './init'
require './models'
require './controllers'
require 'rack/ssl-enforcer'

use Rack::Static, {
  :root => "public",
  :urls => ["/fonts", "/css", "/js", "/img", "/favicon.ico", "/robots.txt"],
  cache_control: 'public,max-age=86400'
}
