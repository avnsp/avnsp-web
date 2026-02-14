require './controllers/admin/base'
require 'base64'

class AdminPartiesController < AdminBaseController
  PARTY_PAGES = %w[attendance emails member_article_list snaps_lottery].freeze

  get '/' do
    @parties = DB[:parties].order(Sequel.desc(:date)).all
    haml :parties
  end

  get '/new' do
    @p = {}
    @members = DB[:members].order(:first_name, :last_name).all
    @organizers = []
    haml :party
  end

  get '/:id' do |id|
    @p = DB[:parties].where(id: id).first
    @members = DB[:members].order(:first_name, :last_name).all
    organizers = DB[:organizers].where(party_id: id).all
    @organizers = @members.select { |m| organizers.any? { |o| o[:member_id] == m[:id] } }
    haml :party
  end

  get '/:id/:page' do |id, page|
    halt 403, 'Invalid page' unless PARTY_PAGES.include?(page)

    @members = DB[:members].order(:first_name, :last_name).all
    @attendances = DB[:attendances]
      .join(:members, id: :member_id)
      .left_join(:right_feet, attendance_id: Sequel[:attendances][:id])
      .select(
        Sequel[:attendances][:id],
        Sequel[:attendances][:allergies],
        Sequel[:attendances][:non_alcoholic],
        Sequel[:attendances][:vegitarian],
        Sequel[:attendances][:message],
        Sequel[:attendances][:timestamp],
        Sequel[:right_feet][:name].as(:rf_name),
        Sequel[:right_feet][:allergies].as(:rf_allergies),
        Sequel[:right_feet][:non_alcoholic].as(:rf_non_alcoholic),
        Sequel[:right_feet][:vegitarian].as(:rf_vegitarian),
        Sequel[:members][:last_name],
        Sequel[:members][:first_name],
        Sequel[:members][:nick],
        Sequel[:members][:email]
      )
      .where(Sequel[:attendances][:party_id] => id)
      .all
      .sort_by { |a| "#{a[:first_name]} #{a[:last_name]}" }
    haml page.to_sym
  end

  post '/:id/attendance' do |id|
    halt 403, "Ingen medlem vald" unless params[:member_id]

    DB.transaction do
      a_id = DB[:attendances].insert(
        vegitarian: params[:vegitarian] == 'true',
        non_alcoholic: params[:non_alcoholic] == 'true',
        allergies: params[:allergies],
        member_id: params[:member_id],
        message: params[:message],
        party_id: id
      )
      if (rf = params[:right_foot]) && !rf['name']&.empty?
        DB[:right_feet].insert(
          attendance_id: a_id,
          name: rf['name'],
          vegitarian: rf['vegitarian'] == 'true',
          non_alcoholic: rf['non_alcoholic'] == 'true',
          allergies: rf['allergies']
        )
      end
    end
    redirect back
  end

  post '/new' do
    p = party_types[params[:type].to_sym]
    party = {
      name: params[:name],
      type: p[:name],
      booking_account_number: p[:ban],
      theme: params[:theme],
      location: params[:location],
      date: params[:date],
      comment: params[:comment],
      attendance_deadline: params[:attendance_deadline],
    }
    party[:price] = params[:price] unless params[:price].empty?
    DB.transaction do
      id = DB[:parties].insert(party)
      Array(params[:organizers]).each do |m|
        next if m.empty?
        DB[:organizers].insert(member_id: m, party_id: id)
      end
      redirect url(id)
    end
  end

  post '/:id/send-invitations' do |id|
    party = DB[:parties].where(id: id).first
    members = DB[:members]
      .join(:transactions, member_id: Sequel[:members][:id])
      .select(Sequel.lit('members.*'))
      .select_append { sum(:sum).as(:balance) }
      .group(Sequel[:members][:id])
      .exclude(Sequel[:members][:email] => nil)
    members.each do |m|
      next if m[:email]&.empty?
      date = party[:date]
      party_date = "#{date.day} #{month(date.month)}"
      last = party[:attendance_deadline]
      last_str = "#{last.day} #{month(last.month)}"
      msg = {
        email: m[:email],
        party_date: party_date,
        party_name: party[:name],
        party_last_att_date: last_str,
        party_id: id,
        nick: m[:nick] || m[:first_name],
        balance: m[:balance],
        balance_after: m[:balance] - party[:price],
        street: m[:street],
        zip: m[:zip],
        city: m[:city],
      }
      publish 'send-invitations', msg
    end
    redirect back
  end

  post '/:id' do |id|
    p = party_types[params[:type].to_sym]
    party = {
      name: params[:name],
      type: p[:name],
      booking_account_number: p[:ban],
      theme: params[:theme],
      location: params[:location],
      date: params[:date],
      comment: params[:comment],
      attendance_deadline: params[:attendance_deadline],
    }
    party[:price] = params[:price] unless params[:price]&.empty?
    DB.transaction do
      if (i = params[:invitation])
        party[:invitation] = handle_file(id, i)
      end
      DB[:parties].where(id: id).update(party)
      DB[:organizers].where(party_id: id).delete
      Array(params[:organizers]).each do |m|
        next if m.empty?
        DB[:organizers].insert(member_id: m, party_id: id)
      end
      redirect url(id)
    end
  end

  delete '/attendance/:id' do |id|
    DB[:right_feet].where(attendance_id: id).delete
    DB[:attendances].where(id: id).delete
    redirect back
  end

  helpers do
    def admin_name
      'parties'
    end

    def party_types
      {
        val: { ban: 3001, name: 'Vårarbetslunch' },
        hal: { ban: 3002, name: 'Höstarbetslunch' },
        vf:  { ban: 4001, name: 'Vårfest' },
        hf:  { ban: 4002, name: 'Höstfest' },
      }
    end

    MONTHS = %w[januari februari mars april maj juni juli
                augusti september oktober november december].freeze
    def month(m)
      MONTHS[m - 1]
    end

    def handle_file(id, f)
      _, ending = f[:type].split('/')
      path = "photos/invitations/#{id}.#{ending}"
      tempfile = f[:tempfile]
      size = tempfile.size
      file = tempfile.read
      publish('file.upload',
              file: Base64.encode64(file),
              size: size,
              content_type: f[:type],
              path: path)
      path
    end
  end
end
