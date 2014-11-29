require './controllers/base'

class AuthController < BaseController
  before do
    unless session[:id] || request.path =~ /^\/log(in|out)|auth/
      redirect "/login?return_url=#{request.url}"
    end
  end

  get '/login' do
    redirect '/' if session[:id]
    haml :login, layout: false
  end

  get '/auth' do
    halt 401 unless params[:token] == 'hello'
    session[:id] = Member[email: params[:email]].id
    redirect '/'
  end

  post '/login' do
    @member = Member[email: params[:email]]
    if @member.nil?
      flash[:info] = 'Den emailen finns inte registrerad.'
    else
      publish 'member.login', @member.to_hash
      flash[:success] = 'Login länken är skickad till din angivna email.'
    end
    redirect back
  end

  post '/logout' do
    session[:id] = nil
    redirect "/"
  end
end
