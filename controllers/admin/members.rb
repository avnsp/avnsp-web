require './controllers/admin/base'

class AdminMembersController < AdminBaseController
  before do
    @data = {
      first_name: params[:first_name]&.strip,
      last_name: params[:last_name]&.strip,
      nick: params[:nick]&.strip,
      studied: params[:studied],
      started: params[:started],
      email: params[:email]&.strip,
      phone: params[:phone],
      street: params[:street]&.strip,
      zip: params[:zip]&.strip,
      city: params[:city]&.strip,
      admin: params[:admin]&.strip,
    }
  end

  get '/' do
    @members = DB[:members].order(:last_name).all
    haml :members
  end

  get '/new' do
    @m = {}
    haml :member
  end

  post '/new' do
    id = DB[:members].insert(@data)
    redirect url(id)
  end

  get '/:id' do |id|
    @m = DB[:members].where(id: id).first
    haml :member
  end

  post '/:id' do |id|
    DB[:members].where(id: id).update(@data)
    redirect back
  end

  helpers do
    def admin_name
      'members'
    end
  end
end
