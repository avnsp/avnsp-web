require './controllers/admin/base'

class AdminMembersController < AdminBaseController
  before do
    @data = {
      first_name: params[:first_name]&.strip,
      last_name: params[:last_name]&.strip,
      nick: (params[:nick]&.strip).then { |n| n.nil? || n.empty? ? nil : n },
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
    balances = DB["SELECT member_id, sum(sum) AS total FROM transactions GROUP BY member_id"]
      .to_hash(:member_id, :total)
    @members = DB[:members].order(:last_name).all.map do |m|
      m.merge(balance: balances[m[:id]])
    end
    haml :members
  end

  post '/remind' do
    members_with_negative_balance.each do |member|
      # Nickname without quotes in emails; skipped when the member has none
      full_name = [member[:first_name], member[:nick], member[:last_name]]
        .map { |part| part.to_s.strip }.reject(&:empty?).join(' ')
      msg = {
        email: member[:email],
        name: full_name,
        balance: member[:total],
      }
      publish('member.reminder', msg)
    end
    redirect url('/')
  end

  get '/new' do
    @m = {}
    haml :member
  end

  post '/new' do
    id = DB[:members].insert(@data)
    redirect url(id)
  end

  post '/:id/merits' do |id|
    @new_merit = { appointment: params[:appointment], start: params[:start], end: params[:end] }
    save_merit(id) { |data| DB[:merits].insert(data.merge(member_id: id.to_i)) }
  end

  post '/:id/merits/:merit_id' do |id, merit_id|
    merit = merit_dataset(id, merit_id)
    save_merit(id) { |data| merit.update(data) }
  end

  post '/:id/merits/:merit_id/delete' do |id, merit_id|
    merit_dataset(id, merit_id).delete
    redirect url("/#{id}#meriter")
  end

  get '/:id' do |id|
    @m = DB[:members].where(id: id).first
    halt 404, 'Medlemmen finns inte' unless @m
    haml :member
  end

  post '/:id' do |id|
    DB[:members].where(id: id).update(@data)
    redirect back
  end

  post '/:id/send-password-reset' do |id|
    member = Member[id]
    halt 404, 'Medlemmen finns inte' unless member
    if member.email.to_s.strip.empty?
      flash[:error] = 'Medlemmen har ingen emailadress.'
    else
      reset_password!(member)
      flash[:info] = "En länk för att byta lösenord har skickats till #{member.email}."
    end
    redirect url("/#{id}")
  end

  helpers do
    def admin_name
      'members'
    end

    def member_merits(member_id)
      DB[:merits].where(member_id: member_id).order(Sequel.desc(:start, nulls: :last)).all
    end

    def merit_dataset(id, merit_id)
      merit = DB[:merits].where(id: merit_id.to_i, member_id: id.to_i)
      halt 404, 'Meriten finns inte' if merit.empty?
      merit
    end

    # Saves through the block, or shows the member page again with an error
    def save_merit(id)
      @m = DB[:members].where(id: id.to_i).first
      halt 404, 'Medlemmen finns inte' unless @m
      @merit_error = merit_error
      if @merit_error
        status 422
        return haml :member
      end
      yield appointment: params[:appointment].strip, start: merit_date(:start), end: merit_date(:end)
      redirect url("/#{id}#meriter")
    end

    def merit_error
      return 'Ange en titel.' if params[:appointment].to_s.strip.empty?
      start_date = merit_date(:start)
      end_date = merit_date(:end)
      return 'Ange giltiga datum.' if start_date == :invalid || end_date == :invalid
      'Slutdatum kan inte vara före startdatum.' if start_date && end_date && end_date < start_date
    end

    # Both dates are optional: older merits may lack them, and a current one has no end
    def merit_date(key)
      value = params[key].to_s.strip
      value.empty? ? nil : Date.iso8601(value)
    rescue Date::Error
      :invalid
    end

    def members_with_negative_balance
      DB["SELECT m.*, t.total
          FROM members m,
          (SELECT member_id, sum(sum) AS total FROM transactions GROUP BY member_id) t
          WHERE m.id = member_id AND total < 0 ORDER BY total"]
    end
  end
end
