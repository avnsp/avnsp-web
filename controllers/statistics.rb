require './controllers/base'
class StatisticsController < BaseController
  get '/' do
    haml :statistics
  end

  get '/data/studied' do
    Member.all.group_by(&:studied).map {|k,v| {:name=> k, :quantity => v.length}}.to_json
  end

  get '/data/started' do
    Member.all.group_by(&:started).map {|k,v| {:name=> k, :quantity => v.length}}.to_json
  end

  get '/data/city' do
    Member.all.group_by(&:city).map {|k,v| {:name=> k, :quantity => v.length}}.to_json
  end

  helpers do
    def name
      "Academian i grafer"
    end
  end
end
