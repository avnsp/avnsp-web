require './controllers/base'

class AuthController < BaseController
  before do
    unless session[:id] || request.path =~ /^\/log(in|out)|forgot/
      redirect "/login?return_url=#{request.url}"
    end
  end

  get '/login' do
    haml :login
  end

  get '/forgot' do
    haml :forgot
  end

  post '/forgot' do
    member = Member[email: params[:email]]
    if member
      flash[:info] = "Ditt nya lösenord skickas till din email"
      password = member.reset_password
      publish "member.reset_password", member.to_hash.merge(password: password)
    else
      flash[:error] = "Fanns ingen med den emailen, borde det göra det? Skicka ett mail till cdo i sådana fall."
    end
    redirect back
  end
  post '/login' do
    @member = Member[nick: params[:nick]]
    if @member and @member.password == params[:password]
      session[:id] = @member.id
      redirect params[:return_url]
    else
      flash[:error] = 'Användarnamn/lösenord är fel'
      redirect back
    end
  end
end
