require 'securerandom'
class EconomyController < BaseController
  configure do
    set :haml, layout: :admin_layout
  end
  get '/' do
    @events = DB[:parties].order(:date).all
    haml :economy
  end
  
  get '/:party_id' do |party_id|
    @party = DB[:parties].where(id: party_id).first
    @articles = DB[:articles].all
    @parties_articles = DB[:parties_articles].where(party_id: @party[:id]).map do |pa|
      a = @articles.select { |a| a[:id] == pa[:article_id] }.first
      pa.merge(article_name: a[:name],
               booking_account_number: @party[:booking_account_number])
    end

    attendances = DB[:attendances].where(party_id: @party[:id]).all
    members = DB[:members].where(id: attendances.map { |a| a[:member_id] }).order(:last_name)
    transactions = DB[:transactions].where(party_id: @party[:id]).all
    @members = members.map do |m|
      trans = {}
      transactions.select { |t| t[:member_id] == m[:id] }.map do |t|
        pa = @parties_articles.select { |pa| pa[:article_id] == t[:article_id] }.first
        trans[t[:article_id]] = (-1 * t[:sum] / pa[:price]).to_i
      end
      m.merge(transactions: trans)
    end

    haml :party_economy
  end

  post '/parties_articles' do
    params[:parties_articles].each do |pa|
      price = pa[:price]
      next if price.nil? or price.to_i == 0
      DB[:parties_articles].insert(article_id: pa[:article_id],
                                   party_id: pa[:party_id],
                                   price: price.to_f)
    end
    redirect back
  end

  post '/transactions' do
    params[:transactions].each do |t|
      next if t[:units].to_i == 0
      sum = -1.0 * t[:units].to_i * t[:price].to_f
      DB[:transactions].insert(party_id: t[:party_id],
                               member_id: t[:member_id],
                               article_id: t[:article_id],
                               booking_account_number: t[:ban],
                               sum: sum,
                               text: "#{t[:units]} #{t[:name]}")
    end
    redirect back
  end

  helpers do
    def full_name member
      [member[:first_name], member[:last_name]].join(' ')
    end
  end
end
