require './controllers/base'

class MemberController < BaseController
  get '/profile' do
    haml :profile
  end

  post '/profile' do
    m = Member.where(id: @member.id)
    m.update(first_name: params[:first_name],
             last_name: params[:last_name],
             nick: params[:nick],
             studied: params[:studied],
             started: params[:started],
             phone: params[:phone],
             street: params[:street],
             zip: params[:zip],
             city: params[:city])
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
