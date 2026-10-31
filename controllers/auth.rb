require "./controllers/base"

class AuthController < BaseController
  RESET_LINK_TTL = 3600

  before do
    unless session[:id] || request.path =~ %r{^/log(in|out)|auth|change-password|forgotten}
      redirect "/login?return_url=#{Rack::Utils.escape(request.path)}"
    end
  end

  get "/login" do
    redirect "/" if session[:id]
    cache_control :public, :must_revalidate, max_age: 24 * 3600
    haml :login, layout: false
  end

  get "/forgotten" do
    haml :forgotten, layout: false
  end

  post "/forgotten" do
    email = params[:email]&.strip&.downcase
    member = Member[email:]
    reset_password!(member) if member
    flash[:info] = "Ett email har skickats"
    redirect back
  end

  get "/change-password" do
    cache_control :public, :must_revalidate, max_age: 0
    @link_valid = token_valid?(params[:token], Member[email: link_email], params[:ts])
    haml :reset_password, layout: false
  end

  post "/change-password" do
    cache_control :public, :must_revalidate, max_age: 0
    email = link_email
    m = Member[email:]
    unless token_valid?(params[:token], m, params[:ts])
      flash[:error] = "Länken är för gammal eller har redan använts. Begär en ny länk här."
      redirect "/forgotten"
    end
    if params[:password].to_s.empty? || params[:password] != params[:password2]
      flash[:error] = "Lösenorden stämmer inte överens. Försök igen."
      redirect "/change-password?#{Rack::Utils.build_query(token: params[:token], ts: params[:ts], email:)}"
    end
    m.update(password: params[:password])
    session[:id] = m.id
    redirect "/"
  end

  post "/login" do
    @member = Member[email: params[:email].downcase.strip]
    if @member.nil?
      flash[:info] = "Den emailen finns inte registrerad."
    elsif @member && @member.password_hash.nil?
      reset_password!(@member)
      flash[:info] =
        "Du har inte registrerat något lösenord, en länk har mailats till dig så du kan registrera ett lösenordet."
    elsif @member && @member.password_hash && @member.password == params[:password]
      session[:id] = @member.id
      redirect safe_return_url(params[:return_url])
    else
      flash[:error] = "Fel lösenord."
    end
    redirect "/login"
  end

  post "/logout" do
    session[:id] = nil
    cache_control :public, :must_revalidate, max_age: 24 * 3600
    redirect "/"
  end

  helpers do
    def safe_return_url(url)
      return "/" if url.nil? || url.empty?
      uri = URI.parse(url)
      return "/" if uri.scheme || uri.host
      path = uri.path.to_s
      path = "/" unless path.start_with?("/")
      query = uri.query ? "?#{uri.query}" : ""
      fragment = uri.fragment ? "##{uri.fragment}" : ""
      "#{path}#{query}#{fragment}"
    rescue URI::InvalidURIError
      "/"
    end

    def link_email
      params[:email].to_s.strip.tr(" ", "+").downcase
    end

    def token_valid?(token, member, ts)
      return false unless member
      (Time.now - RESET_LINK_TTL) < Time.at(ts.to_i) &&
        Rack::Utils.secure_compare(token.to_s, make_token(member, ts))
    end
  end
end
