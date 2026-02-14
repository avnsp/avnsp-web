require './controllers/base'

class PartyController < BaseController
  get '/' do
    @parties = DB[:parties].reverse_order(:date).all
    haml :parties
  end

  get '/:id' do |id|
    @party = Party[id]
    @attendances = @party.attendances_dataset.eager(:member, :right_feet).all
    @albums = Album.where(party_id: id).all
    @organizers = @party.organizers_dataset.eager(:member).all

    # Batch-compute prior attendance counts in one query
    member_ids = @attendances.map(&:member_id)
    @prior_counts = {}
    if member_ids.any?
      type_pattern = @party.type.include?("lunch") ? "%lunch%" : "%fest%"
      party_date = @party.date
      DB[:attendances]
        .join(:parties, id: :party_id)
        .where(Sequel[:attendances][:member_id] => member_ids)
        .where(Sequel.like(Sequel[:parties][:type], type_pattern))
        .where { Sequel[:parties][:date] < party_date }
        .group_and_count(Sequel[:attendances][:member_id])
        .each { |r| @prior_counts[r[:member_id]] = r[:count] }
    end

    @attendances.sort_by! { |a| @prior_counts[a.member_id] || 0 }
    @attendances.reverse!
    haml :party
  end

  get '/:id/buy' do |id|
    @party = Party[id]
    unless @party.attending?(@user.id)
      flash[:error] = 'Du måste vara anmäld till festen'
      redirect url("/#{id}")
    end
    @purchases = { Öl: 0, Snaps: 0, Cider: 0, Bastuöl: 0, Sångbok: 0, Läsk: 0 }
    @user.purchases(id).each do |p|
      @purchases[p.name.to_sym] = p.quantity
    end
    haml :buy
  end

  get '/:id/stream' do |id|
    @password = @username = 'avnsp'
    @party = Party[id]
    unless @party.attending?(@user.id)
      flash[:error] = 'Du måste vara anmäld till festen'
      redirect url("/#{id}")
    end
    @attendances = @party.attendances_dataset.eager(:member).all.map(&:nick).sort
    @purchases = @party.purchases_highchart
    haml :stream, layout: false
  end

  post '/:id/buy' do |id|
    party = Party[id]
    unless party.attending?(@user.id)
      flash[:error] = 'Du måste vara anmäld till festen'
      redirect url("/#{id}")
    end
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
