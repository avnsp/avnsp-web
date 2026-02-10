require './controllers/base'
class StatisticsController < BaseController
  get '/' do
    haml :statistics
  end

  get '/data/studied' do
    DB[:members].group_and_count(:studied).all
      .map { |r| { name: r[:studied], quantity: r[:count] } }.to_json
  end

  get '/data/started' do
    DB[:members].group_and_count(:started).all
      .map { |r| { name: r[:started], quantity: r[:count] } }.to_json
  end

  get '/data/city' do
    DB[:members].group_and_count(:city).all
      .map { |r| { name: r[:city], quantity: r[:count] } }.to_json
  end

  helpers do
    def name
      "Academian i grafer"
    end
  end
end
