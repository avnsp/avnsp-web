require './controllers/base'

class MemberController < BaseController
  get '/' do
    @members = Member.order(:last_name).all
    haml :members
  end

  get '/edit' do
    haml :profile
  end

  post '/edit' do
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
    if f = params[:profile_picture]
      tempfile = f[:tempfile]
      size = tempfile.size
      file = tempfile.read
      path = "photos/profile-pictures/#{@member.id}.jpg"
      m[:profile_picture] = path
      publish('photo.upload',
              file: Base64.encode64(file),
              size: size,
              content_type: f[:type],
              versions: [
                { path: path, quality: 75, resample: 72 },
              ])
    end
    Member.where(id: @member.id).update(m)
    redirect back
  end

  get '/:id' do |id|
    @member = Member[id]
    @parties = @member.parties.sort_by(&:date)
    @transactions = @member.transactions.sort_by(&:timestamp).take(10)
    haml :member
  end

  helpers do
    def name
      "Matrikel"
    end
  end
end
