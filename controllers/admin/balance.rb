require './controllers/admin/base'

class AdminBalanceController < AdminBaseController
  get '/' do
    @members = DB[:members]
      .join(:transactions, member_id: Sequel[:members][:id])
      .select(
        Sequel[:members][:id],
        Sequel[:members][:last_name],
        Sequel[:members][:first_name],
        Sequel.lit("sum(transactions.sum) as balance")
      )
      .group(Sequel[:members][:id], Sequel[:members][:last_name], Sequel[:members][:first_name])
      .order(Sequel.lit("balance"), Sequel[:members][:first_name], Sequel[:members][:last_name])
    @total_balance = @members.map { |m| m[:balance] }.inject(&:+)
    haml :balance
  end

  get '/:member_id' do |member_id|
    @member = DB[:members][id: member_id]
    @transactions = DB[:transactions]
      .left_join(:parties, id: Sequel[:transactions][:party_id])
      .select(
        Sequel[:transactions][:party_id],
        Sequel[:transactions][:text],
        Sequel[:transactions][:timestamp],
        Sequel[:transactions][:sum],
        Sequel[:parties][:name],
        Sequel[:parties][:date].as(:party_date)
      )
      .where(Sequel[:transactions][:member_id] => member_id)
      .order(Sequel[:transactions][:timestamp])
      .all
    @total_balance = @transactions.map { |a| a[:sum] }.inject(&:+)
    haml :member_balance
  end

  helpers do
    def admin_name
      'balance'
    end
  end
end
