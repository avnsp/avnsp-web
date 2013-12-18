require './controllers/base'
class HomeController < BaseController
  get '/' do
    id = session[:id]
    @member = Member[id]
    haml :home
  end
  get '/stream' do
    content_type "text/event-stream"
    topics = ["member.created", "event.created"]
    stream :keep_open do |out|
      sub = subscribe '', *topics do |data, key|
        out << "event: #{key}\ndata: #{data.to_json}\n\n"
      end
      loop do
        begin
          out << ":\n"
          sleep 1
        rescue Exception
          sub.cancel
          break
        end
      end
    end
  end
end
