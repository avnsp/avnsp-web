require './controllers/admin/base'

class AdminDashboardController < AdminBaseController
  get '/' do
    haml :dashboard
  end

  helpers do
    def admin_name
      'dashboard'
    end
  end
end
