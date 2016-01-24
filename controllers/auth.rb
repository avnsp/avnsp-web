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
    unless token_valid?(params[:token], params[:email], params[:ts])
      halt 401, 'Ngt blev fel i autensieringen. Skicka ett email till cdo@academian.se'
    end
    session[:id] = Member[email: params[:email]].id
    redirect '/'
  end

  post '/login' do
    @member = Member[email: params[:email].downcase.strip]
    if @member.nil?
      flash[:info] = 'Den emailen finns inte registrerad.'
    else
      ts = DateTime.now
      publish 'member.login', @member.to_hash.merge(ts: ts.to_s, token: generate_token(@member.email, ts))
      flash[:success] = 'Login länken är skickad till din angivna email.'
    end
    redirect back
  end

  post '/logout' do
    session[:id] = nil
    redirect "/"
  end

  helpers do
    def generate_token(email, ts)
      str = "#{email}:#{ts}:#{ENV['SESSION_SECRET']}"
      Digest::SHA1.hexdigest(str)
    end

    def token_valid?(token, email, ts)
      dt = DateTime.parse(ts)
      dt < (DateTime.now - 300) && token == generate_token(email, params[:ts])
    end
  end
end
