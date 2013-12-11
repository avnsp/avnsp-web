require './controllers/base'
require 'securerandom'
class AdminController < BaseController
  get '/' do
    haml :admin
  end
  post '/member' do
    member = Member.create(first_name: params[:first_name],
                           last_name: params[:last_name],
                           nick: params[:nick],
                           studied: params[:studied],
                           started: params[:started],
                           email: params[:email],
                           phone: params[:phone],
                           street: params[:street],
                           zip: params[:zip],
                           city: params[:city],
                          )
    publish "member.created", member.to_hash
  end
  post '/event' do
    event = Event.create(name: params[:name],
                         theme: params[:theme],
                         location: params[:location],
                         date: params[:date],
                         price: params[:price],
                         comment: params[:comment])
    publish "event.created", event.to_hash
  end
end
