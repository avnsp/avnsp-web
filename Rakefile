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

task default: :test
