require './controllers/base'

class PartyController < BaseController
  get '/' do
    @parties = DB[:parties].reverse_order(:date).all
    haml :parties
  end

  get '/:id' do |id|
    @party = Party[id]
    @attendances = @party.attendances.sort_by(&:member_previus_attendanceise).reverse
    @albums = Album.where(party_id: id).all
    @organizers = @party.organizers
    haml :party
  end

  get '/:id/buy' do |id|
    @party = Party[id]
    @purchases = { Öl: 0, Snaps: 0, Cider: 0, Bastuöl: 0, Sångbok: 0, Läsk: 0 }
    @user.purchases(id).each do |p|
      @purchases[p.name.to_sym] = p.quantity
    end
    haml :buy
  end

  get '/:id/stream' do |id|
    @password = @username = 'avnsp'
    @party = Party[id]
    @attendances = @party.attendances.map(&:nick).sort
    @purchases = @party.purchases_highchart
    haml :stream, layout: false
  end

  post '/:id/buy' do |id|
    a = DB[:articles].where(name: params[:name]).first
    q = params[:q].to_i + params[:change].to_i
    redirect url("/#{id}/buy") if q < 0
    if DB[:purchases].where(party_id: id, member_id: @user.id, article_id: a[:id]).any?
      DB[:purchases].
        where(party_id: id, member_id: @user.id, article_id: a[:id]).
        update(quantity: q)
    else
      DB[:purchases].insert(party_id: id,
                            member_id: @user.id,
                            article_id: a[:id],
                            quantity: q)
    end
    publish("mqtt-bridge.#{id}", Party[id].purchases_highchart)
    redirect url("/#{id}/buy")
  end

  get '/:id/invitation' do |id|
    party = Party[id]
    s3 = Aws::S3::Client.new(region: 'eu-west-1')
    begin
      resp = s3.get_object(bucket: 'avnsp', key: party.invitation)
      content_type resp.content_type
      resp.body.read
    rescue Aws::S3::Errors::NoSuchKey => e
      puts "[WARN] #{e}"
      "Ingen inbjudan är uppladdad för den här festen"
    end
  end

  get '/:id/attend' do |id|
    @attendance = @user.attendances.select { |a| a.party_id == id.to_i }.first
    @attendance ||= Attendance.new
    @party = Party[id]
    haml :attend_form, locals: { party_id: id, a: @attendance, party_type: @party.type }
  end

  post '/:id/attend' do |id|
    rk = if attendance = Attendance[member_id: @user.id, party_id: id]
      attendance.update(vegitarian: params[:vegitarian] == 'true',
                        non_alcoholic: params[:non_alcoholic] == 'true',
                        message: params[:message],
                        allergies: params[:allergies])
      'attendance.update'
    else
      attendance = Attendance.create(vegitarian: params[:vegitarian] == 'true',
                                     non_alcoholic: params[:non_alcoholic] == 'true',
                                     allergies: params[:allergies],
                                     member_id: @user.id,
                                     message: params[:message],
                                     party_id: id)
      'attendance.create'
    end
    attendance.add_right_foot(params[:right_foot]) unless params[:right_foot]&.nil?
    publish rk, attendance.to_hash
    redirect url(id)
  end

  post '/:id/attend/delete' do |id|
    DB[:attendances].where(member_id: @user.id, party_id: id).delete
    redirect url(id)
  end

  helpers do
    def name
      'party'
    end

    def party_articles
    end
  end
end
