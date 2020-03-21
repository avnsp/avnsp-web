require 'sinatra/base'
require 'rack-flash'
require 'haml'
require 'tilt/haml'

class BaseController < Sinatra::Base
  set :views, "./views"
  set :haml, escape_html: true, ugly: true, format: :html5
  set :protection, session: true, :except => :frame_options
  set :protected, true
  use Rack::Flash, sweep: true

  configure :development do
    enable :logging
  end

  before do
    cache_control :public, :must_revalidate, max_age: 0
    @user = Member[session[:id]]
  end

  helpers do
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
