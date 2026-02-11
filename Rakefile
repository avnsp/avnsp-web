require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = 'test/**/*_test.rb'
end

namespace :db do
  desc "Run database migrations"
  task :migrate do
    require 'sequel'
    require 'sequel/extensions/migration'
    Sequel.extension :core_extensions, :pg_json, :pg_json_ops
    db = Sequel.connect(ENV["ELEPHANTSQL_URL"] || "postgres://localhost/avnsp")
    Sequel::Migrator.run(db, './migrations')
    puts "Migrations complete."
  end
end

namespace :dev do
  desc "Create a test user (test@test.com / test) - development only"
  task :seed do
    abort "ERROR: RACK_ENV must be development" unless ENV.fetch("RACK_ENV", "development") == "development"
    db_url = ENV["ELEPHANTSQL_URL"] || "postgres://localhost/avnsp"
    abort "ERROR: Only allowed against localhost databases" unless db_url.include?("localhost")

    require 'sequel'
    require 'bcrypt'
    db = Sequel.connect(db_url)

    email = "test@test.com"
    if db[:members].where(email: email).any?
      puts "User #{email} already exists, skipping."
    else
      db[:members].insert(
        first_name: "Test",
        last_name: "User",
        email: email,
        studied: "F",
        started: 2020,
        password_hash: BCrypt::Password.create("test")
      )
      puts "Created test user: #{email} / test"
    end
  end
end

task default: :test
