require 'sinatra/base'
require 'rack-flash'
require 'haml'
require 'tilt/haml'

class BaseController < Sinatra::Base
  set :views, "./views"
  set :haml, escape_html: true, format: :html5
  set :protection, session: true, :except => :frame_options
  set :protected, true

  configure :development do
    enable :logging
  end

  before do
    cache_control :public, :must_revalidate, max_age: 0
    headers 'Content-Security-Policy' => \
      "default-src 'self'; " \
      "script-src 'self' cdn.jsdelivr.net; " \
      "style-src 'self' 'unsafe-inline'; " \
      "img-src 'self' data: *.s3.eu-west-1.amazonaws.com; " \
      "connect-src 'self' wss://m21.cloudmqtt.com; " \
      "font-src 'self'; " \
      "frame-ancestors 'none'; " \
      "base-uri 'self'; " \
      "form-action 'self'"
    @user = Member[session[:id]]
  end

  helpers do
    def flash
      env['x-rack.flash']
    end

    def htmx?
      request.env['HTTP_HX_REQUEST'] == 'true'
    end

    APP_PUBLIC = File.expand_path('../../public', __FILE__)

    def asset_path(path)
      full = File.join(APP_PUBLIC, path)
      mtime = File.exist?(full) ? File.mtime(full).to_i : 0
      "#{path}?v=#{mtime}"
    end

    def subscribe qname, *topics, &blk
      TH.subscribe(qname, *topics, &blk)
    end

    def publish routing_key, data
      TH.publish routing_key, data
    end

    def cancel_consumer consumer
      TH.cancel consumer
    end
  end
end
