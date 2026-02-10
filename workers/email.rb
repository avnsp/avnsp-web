# frozen_string_literal: true

require "json"
require "mail"

unless ENV["RACK_ENV"] == "development"
  Mail.defaults do
    delivery_method :smtp, {
      address: "email-smtp.us-east-1.amazonaws.com",
      port: 587,
      domain: "academian.se",
      user_name: ENV.fetch("SES_ACCESS_KEY"),
      password: ENV.fetch("SES_SECRET_KEY"),
      authentication: "plain",
      enable_starttls_auto: true,
    }
  end
end

class EmailWorker
  def start
    member_login
    member_reminder
    member_reset_password
    send_invitations
  end

  def member_login
    subscribe("member.login", "member.login") do |_, msg|
      s = Struct.new(:email, :token, :ts, :hostname)
      extras = s.new(msg[:email], msg[:token], msg[:ts], msg[:hostname])
      send_email(msg[:email], "login-länk", "text/html; charset=UTF-8", haml(:login, extras))
    end
  end

  def member_reminder
    subscribe("member.reminder", "member.reminder") do |_, msg|
      body = <<-EMAIL_BODY
      #{msg[:name]}!
      Det här är ett automatgenererat utskick från Academians ekonomiska falang.

      Enligt noteringar i datan är du skyldig Academia Vestigia Nuda Sinistri Pedis #{msg[:balance]} kr. Var vänlig sätt in (minst) detta belopp på föreningens plusgiro 819950-7.


      Om det är något galet med denna anmodan vore jag glad om du hörde av dig.

      Ex officio,

      Chef des Argent

      EMAIL_BODY
      send_email(msg[:email], "Påminnelsemail", "text/plain; charset=UTF-8", body.gsub(/^ */, ""))
    end
  end

  def member_reset_password
    subscribe("member.change-password", "member.reset-password") do |_, msg|
      body = <<-EMAIL_BODY
      Klicka på länken för att ändra lösenordet.

      https://#{msg[:hostname]}/change-password?token=#{msg[:token]}&ts=#{msg[:ts]}&email=#{msg[:email]}

      /CdO
      EMAIL_BODY
      send_email(msg[:email], "Ändra lösenord", "text/plain; charset=UTF-8", body.gsub(/^ */, ""))
    end
  end

  def send_invitations
    subscribe("party.invitation", "send-invitations") do |_, msg|
      s = Struct.new(:nick, :party_date, :party_name, :party_last_att_date,
                     :party_id, :balance, :balance_after, :street, :zip, :city)
      extras = s.new(msg[:nick], msg[:party_date], msg[:party_name],
                     msg[:party_last_att_date], msg[:party_id], msg[:balance],
                     msg[:balance_after], msg[:street], msg[:zip], msg[:city])
      send_email(msg[:email], "Inbjudan #{msg[:party_name]}", "text/html; charset=UTF-8", haml(:invitation, extras))
    end
  end

  private

  def send_email(to, sub, ct, body)
    if ENV["RACK_ENV"] == "development"
      puts body
      return
    end
    m = Mail.new do
      from          "cdo@academian.se"
      to            to
      subject       "[Academian] #{sub}"
      content_type  ct
      body          body
    end
    puts "[INFO] send-email to=#{to} sub=#{sub}"
    if ENV["RACK_ENV"] == "production" || ENV["TEST"]
      m.deliver
    else
      puts "=== EMAIL ==="
      puts m
    end
  rescue ArgumentError => e
    puts "[ERROR] failed-to-send-email to=#{to} sub=#{sub}"
    puts e.inspect
  end

  def haml(file_name, extras)
    file = File.read("./emails/#{file_name}.haml")
    Haml::Template.new { file }.render(extras)
  end
end
