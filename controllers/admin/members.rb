require './controllers/admin/base'

class AdminMembersController < AdminBaseController
  before do
    @data = {
      first_name: params[:first_name]&.strip,
      last_name: params[:last_name]&.strip,
      nick: params[:nick]&.strip,
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
      nick = member[:nick] || ''
      full_name = "#{member[:first_name]} #{nick} #{member[:last_name]}"
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

  get '/:id' do |id|
    @m = DB[:members].where(id: id).first
    haml :member
  end

  post '/:id' do |id|
    DB[:members].where(id: id).update(@data)
    redirect back
  end

  helpers do
    def admin_name
      'members'
    end

    def members_with_negative_balance
      DB["SELECT m.*, t.total
          FROM members m,
          (SELECT member_id, sum(sum) AS total FROM transactions GROUP BY member_id) t
          WHERE m.id = member_id AND total < 0 ORDER BY total"]
    end
  end
end
