require './controllers/base'
class HomeController < BaseController
  get '/' do
    id = session[:id]
    @member = Member[id]
    haml :home
  end
end
