require 'sinatra/base'
require 'sinatra/flash'
require 'haml'
require 'tilt/haml'

class BaseController < Sinatra::Base
  register Sinatra::Flash
  set :views, "./views"
  set :haml, escape_html: true, ugly: true, format: :html5
  set :protection, session: true
  set :protected, true

  configure :development do
    enable :logging
  end

  before do
    cache_control :public, :must_revalidate, max_age: 24 * 3600
    if ENV['RACK_ENV'] == 'production'
      @user = Member[session[:id]]
    else
      @user = Member.order(:id).first
    end
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
