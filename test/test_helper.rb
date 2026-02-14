ENV['RACK_ENV'] = 'test'
ENV['SES_ACCESS_KEY'] ||= 'test'
ENV['SES_SECRET_KEY'] ||= 'test'
ENV['SESSION_SECRET'] ||= 'test-secret-that-is-long-enough-for-rack-3-session-cookie-encryption-requirement-64chars'

require 'bundler/setup'
require 'minitest/autorun'
require 'rack/test'
require 'webmock/minitest'
require 'rack-flash'
require 'database_cleaner-sequel'
require 'securerandom'
require 'digest'

# --- Database setup (bypass init.rb) ---
require 'sequel'
require 'sequel/extensions/migration'
Sequel.extension :core_extensions, :pg_json, :pg_json_ops

TEST_DB_NAME = "avnsp_test"
system("createdb #{TEST_DB_NAME} 2>/dev/null")
DB = Sequel.connect("postgres://localhost/#{TEST_DB_NAME}")
Sequel::Migrator.run(DB, './migrations')

# Migration 04 uses `JSON :data` which doesn't create the column (JSON is a Ruby constant).
# Add it if missing.
unless DB[:events].columns.include?(:data)
  DB.alter_table(:events) { add_column :data, :json }
end

# --- Globals that init.rb normally sets ---
FQDN = "www.academian.se"

require_relative 'support/thumper_stub'
TH = ThumperStub.new

require 'aws-sdk-s3'
Aws.config.update(stub_responses: true, region: 'eu-west-1')

# --- Load application code ---
require './models'
require './controllers'
require './workers'

# --- WebMock ---
WebMock.disable_net_connect!

# --- DatabaseCleaner ---
DatabaseCleaner[:sequel].db = DB
DatabaseCleaner[:sequel].strategy = :transaction

# --- Base test class ---
class Minitest::Test
  def setup
    DatabaseCleaner[:sequel].start
    TH.reset!
  end

  def teardown
    DatabaseCleaner[:sequel].clean
  end
end

# --- Teardown: drop test DB after suite ---
Minitest.after_run do
  DB.disconnect
  system("dropdb #{TEST_DB_NAME}")
end

# --- Factory helpers ---
def create_booking_account(number: 2021, name: "Test")
  DB[:booking_accounts].insert_conflict.insert(number: number, name: name)
  number
end

def create_admin(attrs = {})
  create_member({ admin: true }.merge(attrs))
end

def create_member(attrs = {})
  defaults = {
    first_name: "Erik",
    last_name: "Svensson",
    email: "m#{SecureRandom.hex(4)}@academian.se",
    studied: "F",
    started: 2015
  }
  Member.create(defaults.merge(attrs))
end

def create_party(attrs = {})
  ba = attrs.delete(:_booking_account) || 2021
  create_booking_account(number: ba)
  defaults = {
    name: "Testfest",
    date: Date.today + 7,
    type: "fest",
    attendance_deadline: Date.today + 5,
    booking_account_number: ba
  }
  Party.create(defaults.merge(attrs))
end

def create_attendance(member: nil, party: nil, attrs: {})
  member ||= create_member
  party ||= create_party
  defaults = {
    member_id: member.id,
    party_id: party.id,
    vegitarian: false,
    non_alcoholic: false
  }
  Attendance.create(defaults.merge(attrs))
end

def create_album(member: nil, party: nil, attrs: {})
  member ||= create_member
  party ||= create_party
  defaults = {
    name: "Testalbum",
    created_by: member.id,
    party_id: party.id
  }
  Album.create(defaults.merge(attrs))
end

def create_photo(album: nil, attrs: {})
  album ||= create_album
  defaults = {
    name: "test.jpg",
    path: "photos/#{SecureRandom.uuid}.jpg",
    thumb_path: "photos/#{SecureRandom.uuid}.thumb.jpg",
    original_path: "photos/#{SecureRandom.uuid}.orig.jpg",
    album_id: album.id
  }
  Photo.create(defaults.merge(attrs))
end

def create_article(name: "Öl")
  existing = Article.where(name: name).first
  return existing if existing
  Article.create(name: name)
end

def create_transaction(member:, sum:, text: "Test", booking_account_number: 2021)
  create_booking_account(number: booking_account_number)
  Transaction.create(
    member_id: member.id,
    sum: sum,
    text: text,
    booking_account_number: booking_account_number
  )
end

def create_purchase(member:, party:, article:, quantity: 1)
  Purchase.create(
    member_id: member.id,
    party_id: party.id,
    article_id: article.id,
    quantity: quantity
  )
end

# --- Rack app builder for controller tests ---
def build_app
  Rack::Builder.new do
    use Rack::Session::Cookie, secret: ENV['SESSION_SECRET'], httponly: true
    use Rack::Flash, sweep: true, helper: false
    use AuthController
    map '/' do
      run HomeController
    end
    map '/party' do
      run PartyController
    end
    map '/album' do
      run AlbumController
    end
    map '/member' do
      run MemberController
    end
    map '/statistics' do
      run StatisticsController
    end
    map '/cheferiet' do
      map '/members' do
        run AdminMembersController
      end
      map '/parties' do
        run AdminPartiesController
      end
      map '/economy' do
        run AdminEconomyController
      end
      map '/balance' do
        run AdminBalanceController
      end
      map '/reminder' do
        run AdminReminderController
      end
      map '/' do
        run AdminDashboardController
      end
    end
  end
end

# --- Controller test base class ---
class ControllerTest < Minitest::Test
  include Rack::Test::Methods

  def app
    @app ||= build_app
  end

  def login_as(member)
    env 'rack.session', { id: member.id }
  end

  # Override env to accumulate settings
  def env(key, value)
    @custom_env ||= {}
    @custom_env[key] = value
  end

  def custom_env
    @custom_env || {}
  end

  def get(uri, params = {}, env = {}, &block)
    super(uri, params, custom_env.merge(env), &block)
  end

  def post(uri, params = {}, env = {}, &block)
    super(uri, params, custom_env.merge(env), &block)
  end

  def put(uri, params = {}, env = {}, &block)
    super(uri, params, custom_env.merge(env), &block)
  end

  def delete(uri, params = {}, env = {}, &block)
    super(uri, params, custom_env.merge(env), &block)
  end

  def setup
    super
    @custom_env = {}
  end
end
