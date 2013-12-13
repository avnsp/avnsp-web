require 'sinatra/base'
require 'sinatra/flash'
require 'sinatra/reloader'
require 'haml'

class BaseController < Sinatra::Base
  register Sinatra::Flash
  set :views, "./views"
  set :haml, escape_html: true

  configure :development do
    enable :logging
  end

  register Sinatra::Reloader if development?

  configure do
    TH.with_channel do |ch|
      @@ch = ch
    end
  end
  helpers do
    def subscribe qname, *topics, &blk
      @@ch.subscribe(qname, *topics, &blk)
    end
    def publish routing_key, data
      @@ch.publish routing_key, data
    end
  end
end
