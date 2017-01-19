require './controllers/base'

class MemberController < BaseController
  get '/' do
    @members = Member.all.sort_by(&:last_name)
    haml :members
  end

  get '/profile-edit' do
    haml :profile
  end

  get '/profile-picture' do
    haml :profile_picture
  end

  post '/profile-picture' do
    f = params[:cropped]
    return redirect back unless f
    tempfile = f[:tempfile]
    size = tempfile.size
    file = tempfile.read
    _, ending = f[:type].split('/')
    path = "photos/profile-pictures/#{@user.id}_#{Time.now.to_i}.#{ending}"
    Member[@user.id].update(profile_picture: path)
    publish('photo.upload',
            file: Base64.encode64(file),
            size: size,
            content_type: f[:type],
            versions: [
              { path: path, quality: 95, resample: 95},
              { path: "#{path}.thumb", quality: 95, resample: 95, resize: 112 }
            ])
  end

  put '/:id/nick' do |id|
    nick = params[:nick]
    nick = nil if nick.empty?
    m = Member[id]
    m.update(nick: nick)
    content_type :text
    m.full_name
  end

  post '/profile-edit' do
    m = {
      first_name: params[:first_name],
      last_name: params[:last_name],
      email: params[:email],
      studied: params[:studied],
      started: params[:started],
      phone: params[:phone],
      street: params[:street],
      city: params[:city],
      zip: params[:zip].strip
    }
    Member.where(id: @user.id).update(m)
    redirect back
  end

  get '/:id' do |id|
    @member = Member[id]
    @parties = @member.parties(Date.today)
    @transactions = @member.transactions_dataset.reverse_order(:timestamp).take(10)
    @merits = @member.merits
    haml :member
  end

  get '/:id/transactions' do |id|
    member = Member[id]
    @transactions = member.transactions
    haml :transactions
  end

  helpers do
    def name
      "Matrikel"
    end
  end
end
