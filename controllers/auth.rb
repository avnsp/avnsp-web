require './controllers/base'

class AuthController < BaseController
  before do
    unless session[:id] || request.path =~ /^\/log(in|out)|auth|change-password|forgotten/
      redirect "/login?return_url=#{request.url}"
    end
  end

  get '/login' do
    redirect '/' if session[:id]
    cache_control :public, :must_revalidate, max_age: 24 * 3600
    haml :login, layout: false
  end

  get '/forgotten' do
    haml :forgotten, layout: false
  end

  post '/forgotten' do
    email = params[:email]&.strip.downcase
    reset_password!(email) if Member[email: email]
    flash[:info] = 'Ett email har skickats'
    redirect back
  end

  get '/change-password' do
    cache_control :public, :must_revalidate, max_age: 0
    ts = params[:ts]
    email = params[:email].strip.tr(' ', '+').downcase
    token = params[:token]
    @error = :token if token != make_token(email, ts)
    @error = :timestamp if Time.at(ts.to_i) < (Time.now - 24 * 3600)
    haml :reset_password, layout: false
  end

  post '/change-password' do
    cache_control :public, :must_revalidate, max_age: 0
    email = params[:email].strip.tr(' ', '+').downcase
    if (m = Member[email: email]) && token_valid?(params[:token], email, params[:ts])
      m.update(password: params[:password])
      session[:id] = m.id
    else
      flash[:error] = 'Ngt blev fel prova att kopiera länken manuellt från emailen om inte det funkar maila cdo@academian.se'
    end
    redirect '/'
  end

  post '/login' do
    @member = Member[email: params[:email].downcase.strip]
    if @member.nil?
      flash[:info] = 'Den emailen finns inte registrerad.'
    elsif @member && @member.password_hash.nil?
      reset_password!(@member.email)
      flash[:info] = 'Du har inte registrerat något lösenord, en länk har mailats till dig så du kan registrera ett lösenordet.'
    elsif @member && @member.password_hash && @member.password == params[:password]
      session[:id] = @member.id
    else
    end
    redirect back
  end

  post '/logout' do
    session[:id] = nil
    cache_control :public, :must_revalidate, max_age: 24 * 3600
    redirect "/"
  end

  helpers do
    def reset_password!(email)
      DB.transaction do
        member = Member[email: email]
        member.update(password_hash: nil)
        ts = Time.now.to_i
        hostname = ENV['RACK_ENV'] == 'production' ? FQDN : 'localhost:9292'
        token = make_token(member.email, ts)
        msg = { email: member.email, ts: ts, hostname: hostname, token: token }
        publish('member.reset-password', msg)
      end
    end

    def make_token(email, ts)
      str = "#{email}:#{ts}:#{ENV['SESSION_SECRET'] || 'avnsp'}"
      Digest::SHA1.hexdigest(str)
    end

    def token_valid?(token, email, ts)
      (Time.now - 1800) < Time.at(ts.to_i) && token == make_token(email, ts)
    end
  end
end
