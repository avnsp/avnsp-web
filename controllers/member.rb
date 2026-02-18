require './controllers/base'

class MemberController < BaseController
  get '/' do
    ds = Member.dataset
    if params[:q] && !params[:q].empty?
      q = "%#{params[:q]}%"
      ds = ds.where(
        Sequel.ilike(:first_name, q) |
        Sequel.ilike(:last_name, q) |
        Sequel.ilike(:nick, q) |
        Sequel.ilike(:email, q) |
        Sequel.ilike(:studied, q)
      )
    end
    sort_col = %w[last_name first_name nick studied started email].include?(params[:sort]) ? params[:sort].to_sym : :last_name
    sort_dir = params[:order] == 'desc' ? Sequel.desc(sort_col) : Sequel.asc(sort_col)
    @members = ds.order(sort_dir).all
    @sort = params[:sort] || 'last_name'
    @order = params[:order] || 'asc'
    if htmx?
      haml :_members_table, layout: false
    else
      haml :members
    end
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
    publish('photo.upload',
            file: Base64.encode64(file),
            size: size,
            content_type: f[:type],
            member_id: @user.id,
            profile_picture: path,
            versions: [
              { path: path, quality: 95, resample: 95},
              { path: "#{path}.thumb", quality: 95, resample: 95, resize: 112 }
            ])
  end

  put '/:id/nick' do |id|
    nick = params[:nick] || request.env['HTTP_HX_PROMPT']
    nick = nil if nick.nil? || nick.empty?
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
