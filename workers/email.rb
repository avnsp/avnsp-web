require 'json'
require 'mail'

Mail.defaults do
  delivery_method :smtp, { 
    :address              => "email-smtp.us-east-1.amazonaws.com",
    :port                 => 587,
    :domain               => "academian.se",
    :user_name            => ENV.fetch('SES_ACCESS_KEY'),
    :password             => ENV.fetch('SES_SECRET_KEY'),
    :authentication       => 'plain',
    :enable_starttls_auto => true
  }
end

class EmailWorker
  def start
    subscribe("member.login", "member.login") do |_, msg|
      send msg[:email], "[Academian] login-länk", haml(:login, msg)
    end
  end

  private
  def send to, sub, body
    if ENV['RACK_ENV'] == 'development'
      puts body
      return
    end
    Mail.deliver do
      from          'auth@academian.se'
      to            to
      subject       sub
      content_type  'text/html; charset=UTF-8'
      body          body
    end 
  end

  def haml(file_name, extras)
    file = File.read("./emails/#{file_name}.haml")
    engine = Haml::Engine.new(file)
    s = Struct.new(:email, :token, :ts, :hostname)
    engine.render(s.new(extras[:email], extras[:token], extras[:ts], extras[:hostname]))
  end
end
