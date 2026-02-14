require './controllers/admin/base'

class AdminEconomyController < AdminBaseController
  get '/' do
    @events = DB[:parties].order(Sequel.desc(:date)).all
    haml :economy
  end

  get '/deposit' do
    @members = DB[:members].all
    haml :deposit
  end

  post '/deposit' do
    @errors = []
    @errors << "Datum måste anges" if params[:date]&.empty?
    @errors << "Måste ange belopp" if params[:sum]&.empty?
    @errors << "Medlemmen finns inte" if params[:member_id]&.empty?
    if @errors.any?
      @members = DB[:members].all
      halt 401, haml(:deposit)
    end
    DB[:transactions].insert(
      booking_account_number: 1920,
      text: 'Insättning',
      timestamp: params[:date],
      sum: params[:sum].to_f,
      member_id: params[:member_id]
    )
    redirect back
  end

  get '/:party_id' do |party_id|
    @party = DB[:parties].where(id: party_id).first
    purchases = DB[:purchases].where(party_id: @party[:id]).all
    @articles = DB[:articles].order(:name).all
    @parties_articles = DB[:parties_articles].where(party_id: @party[:id]).map do |pa|
      a = @articles.find { |ar| ar[:id] == pa[:article_id] }
      pa.merge(article_name: a[:name],
               booking_account_number: @party[:booking_account_number])
    end

    attendances = DB[:attendances].where(party_id: @party[:id]).all
    members = DB[:members].where(id: attendances.map { |a| a[:member_id] }).order(:first_name)
    @members = members.map do |m|
      ps = {}
      purchases.select { |t| t[:member_id] == m[:id] }.each do |p|
        pa = @articles.find { |a| a[:id] == p[:article_id] }
        next unless pa
        ps[p[:article_id]] = p[:quantity]
      end
      m.merge(purchases: ps)
    end
    haml :party_economy
  end

  post '/parties_articles' do
    DB.transaction do
      DB[:parties_articles].where(party_id: params[:parties_articles].first[:party_id]).delete
      params[:parties_articles].each do |pa|
        price = pa[:price]
        next if price.nil? || price.to_i == 0
        DB[:parties_articles].insert(
          article_id: pa[:article_id],
          party_id: pa[:party_id],
          price: price.to_f
        )
      end
    end
    redirect back
  end

  post '/:id/transactions' do |id|
    DB.transaction do
      params[:purchases].each do |p|
        p_db = DB[:purchases].where(
          member_id: p['member_id'],
          article_id: p['article_id'],
          party_id: id
        )
        if p_db.any?
          p_db.update(quantity: p['quantity'])
        else
          next if p['quantity'].to_i == 0
          DB[:purchases].insert(
            member_id: p['member_id'],
            article_id: p['article_id'],
            party_id: id,
            quantity: p['quantity']
          )
        end
      end
    end
    DB.transaction do
      party = DB[:parties].where(id: id).first
      DB[:transactions].where(party_id: id).delete
      pas = DB[:parties_articles].where(party_id: id).all
      articles = DB[:articles].where(id: pas.map { |pa| pa[:article_id] }.uniq).all
      DB[:purchases].where(party_id: id).each do |p|
        next if p[:quantity].to_i == 0
        pa = pas.find { |a| a[:article_id] == p[:article_id] }
        next unless pa
        a = articles.find { |ar| ar[:id] == p[:article_id] }
        sum = -1.0 * p[:quantity].to_i * pa[:price].to_f
        DB[:transactions].insert(
          party_id: id,
          member_id: p[:member_id],
          article_id: a[:id],
          booking_account_number: party[:booking_account_number],
          sum: sum,
          text: "#{p[:quantity]} #{a[:name]}"
        )
      end
    end
    redirect back
  end

  helpers do
    def admin_name
      'economy'
    end

    def full_name(member)
      [member[:first_name], member[:last_name]].join(' ')
    end
  end
end
