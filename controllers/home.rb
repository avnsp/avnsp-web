require './controllers/base'

class HomeController < BaseController
  get '/' do
    id = session[:id]
    @member = Member[id]
    @events = Event.order(:timestamp).take(10).to_json;
    haml :home
  end

  get '/stream' do
    content_type "text/event-stream"
    topics = ["event.member.created", "event.party.created", "event.photo.created"]
    stream :keep_open do |out|
      sub = subscribe '', *topics do |data, key|
        out << "event: #{key}\ndata: #{data.to_json}\n\n"
      end
      loop do
        begin
          out << ":\n"
          sleep 15
        rescue Exception
          sub.cancel
          break
        end
      end
    end
  end
end
