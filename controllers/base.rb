require 'sinatra/base'
require 'rack-flash'
require 'haml'
require 'tilt/haml'
require 'openssl'

class BaseController < Sinatra::Base
  set :views, "./views"
  set :haml, escape_html: true, format: :html5
  set :protection, session: true, :except => :frame_options
  set :protected, true

  configure :development do
    enable :logging
  end

  before do
    cache_control :public, :must_revalidate, max_age: 0
    headers 'Content-Security-Policy' => \
      "default-src 'self'; " \
      "script-src 'self' cdn.jsdelivr.net; " \
      "style-src 'self' 'unsafe-inline'; " \
      "img-src 'self' data: *.s3.eu-west-1.amazonaws.com; " \
      "connect-src 'self' wss://m21.cloudmqtt.com; " \
      "font-src 'self'; " \
      "frame-ancestors 'none'; " \
      "base-uri 'self'; " \
      "form-action 'self'"
    @user = Member[session[:id]]
  end

  helpers do
    def flash
      env['x-rack.flash']
    end

    def htmx?
      request.env['HTTP_HX_REQUEST'] == 'true'
    end

    APP_PUBLIC = File.expand_path('../../public', __FILE__)

    def asset_path(path)
      full = File.join(APP_PUBLIC, path)
      mtime = File.exist?(full) ? File.mtime(full).to_i : 0
      "#{path}?v=#{mtime}"
    end

    # Email address that a narrow table column may wrap before the @
    def email_breakable(email)
      Rack::Utils.escape_html(email.to_s).sub('@', '<wbr>@')
    end

    def csrf_token_tag
      token = session[:csrf] || ''
      %(<input type="hidden" name="authenticity_token" value="#{Rack::Utils.escape_html(token)}">)
    end

    def csrf_token
      session[:csrf] || ''
    end

    # Emails a link for choosing a new password. The current password keeps
    # working until the link is used.
    def reset_password!(member)
      ts = Time.now.to_i
      hostname = ENV["RACK_ENV"] == "production" ? FQDN : "localhost:9292"
      token = make_token(member, ts)
      msg = { email: member.email, ts:, hostname:, token: }
      publish("member.reset-password", msg)
    end

    # Signs the password hash too, so a link stops working once it has been used
    def make_token(member, ts)
      secret = ENV["SESSION_SECRET"]
      raise "SESSION_SECRET must be set to generate password reset tokens" if secret.nil? || secret.empty?
      OpenSSL::HMAC.hexdigest("SHA256", secret, [member.email, ts, member.password_hash].compact.join(":"))
    end

    def subscribe qname, *topics, &blk
      TH.subscribe(qname, *topics, &blk)
    end

    def publish routing_key, data
      TH.publish routing_key, data
    end

    def cancel_consumer consumer
      TH.cancel consumer
    end
  end
end
