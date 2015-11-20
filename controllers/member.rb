require './controllers/base'

class MemberController < BaseController
  get '/profile' do
    haml :profile
  end

  post '/profile' do
    m = {
      first_name: params[:first_name],
      last_name: params[:last_name],
      studied: params[:studied],
      started: params[:started],
      phone: params[:phone],
      street: params[:street],
      city: params[:city]
    }
    m[:zip] = nil if params[:zip].empty?
    m[:nick] = nil if  params[:nick].empty?
    Member.where(id: @member.id).update(m)
    redirect back
  end

  get '/:id' do |id|
    @member = Member[id]
    @parties = @member.parties.sort_by(&:date)
    haml :member
  end

  helpers do
    def name
      "Member"
    end
  end
end
