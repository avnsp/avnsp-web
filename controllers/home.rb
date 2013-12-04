require './controllers/base'
class HomeController < BaseController
  get '/' do
    "hello"
  end
end
