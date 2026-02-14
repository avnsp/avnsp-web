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

class CloudFrontForwaredProtoFix
  def initialize(app)
    @app = app
  end

  def call(env)
    if env['HTTP_CLOUDFRONT_FORWARDED_PROTO']
      env['SERVER_NAME'] = env['HTTP_HOST'] = FQDN
    end
    @app.call(env)
  end
end

use CloudFrontForwaredProtoFix
use Rack::SslEnforcer, hsts: true if ENV['RACK_ENV'] == 'production'
use Rack::Deflater

use Rack::Session::Cookie, {
  :secret => ENV['SESSION_SECRET'] || 'xKU9Ybq23jafjhh',
  :httponly => true,
  :secure => (ENV['RACK_ENV'] == 'production'),
  :expire_after => 24 * 3600 * 30,
}

use Rack::Flash, sweep: true, helper: false
use AuthController

map '/' do
  run HomeController
end

map '/party' do
  run PartyController
end

map '/album' do
  run AlbumController
end

map '/member' do
  run MemberController
end

map '/statistics' do
  run StatisticsController
end

map '/cheferiet' do
  map '/members' do
    run AdminMembersController
  end
  map '/parties' do
    run AdminPartiesController
  end
  map '/economy' do
    run AdminEconomyController
  end
  map '/balance' do
    run AdminBalanceController
  end
  map '/reminder' do
    run AdminReminderController
  end
  map '/' do
    run AdminDashboardController
  end
end
