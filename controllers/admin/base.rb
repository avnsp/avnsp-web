require './controllers/base'

class AdminBaseController < BaseController
  set :views, './views/admin'

  before do
    halt 403, 'Forbidden' unless @user&.admin
  end

  helpers do
    def admin_name
      'admin'
    end
  end
end
