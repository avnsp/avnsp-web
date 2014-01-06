require './controllers/base'

class PartyController < BaseController
  get '/:id' do |id|
    @party = Party[id]
    haml :party
  end
end
