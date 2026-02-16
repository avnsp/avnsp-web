require './controllers/base'

class HomeController < BaseController
  get '/' do
    @parties = Party.eager(:attendances).where(Sequel.lit("NOW() < date + 1")).order(:attendance_deadline).all
    haml :home
  end

  get '/stream', provides: "text/event-stream" do
    topics = ["event.member.created", "event.party.created", "event.photo.created"]
    stream :keep_open do |out|
      c = subscribe '', *topics do |key, data|
        begin
          out << "event: #{key}\ndata: #{data.to_json}\n\n"
        rescue StandardError
          cancel_consumer self
          raise "[ERROR] closed channel"
        end
      end
      loop do
        begin
          out << ":\n"
          sleep 10
        rescue StandardError
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
