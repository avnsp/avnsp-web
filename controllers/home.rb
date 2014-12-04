require './controllers/base'

class HomeController < BaseController
  before do
    @member = Member[session[:id]]
  end

  get '/' do
    id = session[:id]
    @member = Member[id]
    @events = Event.order(:timestamp).take(10).to_json;
    haml :home
  end

  get '/stream', provides: "text/event-stream" do
    topics = ["event.member.created", "event.party.created", "event.photo.created"]
    stream :keep_open do |out|
      c = subscribe '', *topics do |key, data|
        begin
          out << "event: #{key}\ndata: #{data.to_json}\n\n"
        rescue Exception
          cancel_consumer self
          raise "[ERROR] closed channel"
        end
      end
      loop do
        begin
          out << ":\n"
          sleep 10
        rescue Exception
          cancel_consumer c
          break
        end
      end
    end
  end

  helpers do
    def name
      'home'
    end
  end
end
