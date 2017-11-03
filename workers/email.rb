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
      s = Struct.new(:email, :token, :ts, :hostname)
      extras = s.new(msg[:email], msg[:token], msg[:ts], msg[:hostname])
      send(msg[:email], "login-länk", 'text/html; charset=UTF-8', haml(:login, extras))
    end
    
    subscribe("member.change-password", "member.reset-password") do |_, msg|
      body = <<-EOF
      Klicka på länken för att ändra lösenordet.

      https://#{msg[:hostname]}/change-password?token=#{msg[:token]}&ts=#{msg[:ts]}&email=#{msg[:email]}
      
      /CdO
      EOF
      send(msg[:email], 'Ändra lösenord', 'text/plain; charset=UTF-8', body.gsub(/^ */, ''))
    end

    subscribe('party.invitation', 'send-invitations') do |_, msg|
      s = Struct.new(:nick, :party_date, :party_name, :party_last_att_date,
                     :party_id, :balance, :balance_after, :street, :zip, :city)
      extras = s.new(msg[:nick], msg[:party_date], msg[:party_name],
                     msg[:party_last_att_date], msg[:party_id], msg[:balance],
                     msg[:balance_after], msg[:street], msg[:zip], msg[:city])
      send(msg[:email], "Inbjudan #{msg[:party_name]}", 'text/html; charset=UTF-8', haml(:invitation, extras))
    end
  end

  private
  def send to, sub, ct, body
    if ENV['RACK_ENV'] == 'development'
      puts body
      return
    end
    m = Mail.new do
      from          'cdo@academian.se'
      to            to
      subject       "[Academian] #{sub}"
      content_type  ct
      body          body
    end 
    puts "[INFO] send-email to=#{to} sub=#{sub}"
    if ENV['RACK_ENV'] == 'production' || ENV['TEST']
      m.deliver
    else
      puts "=== EMAIL ==="
      puts m.to_s
    end
  end

  def haml(file_name, extras)
    file = File.read("./emails/#{file_name}.haml")
    engine = Haml::Engine.new(file)
    engine.render(extras)
  end
end
