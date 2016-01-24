require './controllers/base'

class MemberController < BaseController
  get '/' do
    @members = Member.all.sort_by(&:last_name)
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
      city: params[:city],
      zip: params[:zip].strip
    }
    m[:nick] = nil if  params[:nick].empty?
    if f = params[:profile_picture]
      tempfile = f[:tempfile]
      size = tempfile.size
      file = tempfile.read
      _, ending = f[:type].split('/')
      path = "photos/profile-pictures/#{@user.id}_#{Time.now.to_i}.#{ending}"
      m[:profile_picture] = path
      publish('photo.upload',
              file: Base64.encode64(file),
              size: size,
              content_type: f[:type],
              versions: [
                { path: path, quality: 80, resample: 80, resize: 820 },
                { path: "#{path}.thumb", quality: 80, resample: 80, resize: 112 }
              ])
    end
    Member.where(id: @user.id).update(m)
    redirect back
  end

  get '/:id' do |id|
    @member = Member[id]
    @parties = @member.parties.sort_by(&:date)
    @transactions = @member.transactions_dataset.reverse_order(:timestamp).take(10)
    @merits = @member.merits
    haml :member
  end

  helpers do
    def name
      "Matrikel"
    end
  end
end
