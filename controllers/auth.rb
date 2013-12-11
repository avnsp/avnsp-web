require './controllers/base'

class AuthController < BaseController
  before do
    unless session[:id] || request.path =~ /^\/log(in|out)/
      redirect "/login?return_url=#{request.url}"
    end
  end
  get '/login' do
    haml :login
  end
  post '/login' do
    @member = Member[nick: params[:nick]]
    if @member.password == params[:password]
      session[:id] = @member.id
      redirect params[:return_url]
    else
      redirect 
    end
  end
end
