require './controllers/base'

class AuthController < BaseController
  before do
    cache_control :public, max_age: 24 * 3600
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
      ts = Time.now.to_i
      publish 'member.login', @member.to_hash.merge(ts: ts, token: generate_token(@member.email, ts))
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
      (Time.now - 300) < Time.at(ts.to_i) && token == generate_token(email, ts)
    end
  end
end
