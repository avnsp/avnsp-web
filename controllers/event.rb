require './controllers/base'

class EventController < BaseController
  get '/:id' do |id|
    @event = Event[id]
    haml :event
  end
end
