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
    subscribe("member.mailer.create", "member.created") do |_, msg|
      plan = msg[:plan]
      email_body = msg
      send(msg[:email], "Välkommen till Academian", email_body)
    end

    subscribe("member.login", "member.login") do |_, msg|
      @email = msg[:email]
      @token = "hello"
      send msg[:email], "[Academian] login länk", haml(:login)
    end
  end

  private
  def send to, sub, body
    Mail.deliver do
      from          'auth@academian.se'
      to            to
      subject       sub
      content_type  'text/html; charset=UTF-8'
      body          body
    end 
  end

  def haml file_name
    file = File.read("./emails/#{file_name}.haml")
    engine = Haml::Engine.new(file)
    s = Struct.new(:email, :token)
    engine.render(s.new(@email, @token))
  end
end
