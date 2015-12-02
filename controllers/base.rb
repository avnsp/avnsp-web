require 'sinatra/base'
require 'sinatra/flash'
require 'sinatra/reloader'
require 'haml'
require 'tilt/haml'

class BaseController < Sinatra::Base
  register Sinatra::Flash
  set :views, "./views"
  set :haml, format: :html5, escape_html: true

  configure :development do
    enable :logging
  end

  before do
    if ENV['RACK_ENV'] == 'production'
      @user = Member[session[:id]]
    else
      @user = Member.order(:id).first
    end
  end

  register Sinatra::Reloader if development?

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
