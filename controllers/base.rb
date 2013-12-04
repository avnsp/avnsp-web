require 'sinatra/base'
require 'sinatra/flash'

class BaseController < Sinatra::Base
  register Sinatra::Flash
  set :views, "./views"
  set :haml, escape_html: true

  configure :development do
    enable :logging
  end
end
