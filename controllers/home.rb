require './controllers/base'
class HomeController < BaseController
  get '/' do
    id = session[:id]
    @member = Member[id]
    haml :home
  end
  get '/stream' do
    content_type "text/event-stream"
    stream :keep_alive => true do |out|
      out << 'data: "hej"\n\n'
    end
  end
  helpers do
    def next_events
      today = Date.today
      events = Event.
        where(date: (today..today.next_year)).
        order(:date)
    end
  end
end
