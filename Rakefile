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

namespace :fix do
  desc "Revert profile_picture paths to match actual S3 files"
  task :profile_pictures do
    require 'sequel'
    require 'aws-sdk-s3'
    Sequel.extension :core_extensions, :pg_json, :pg_json_ops
    db = Sequel.connect(ENV["ELEPHANTSQL_URL"] || "postgres://localhost/avnsp")

    aws_opts = { region: 'eu-west-1' }
    if ENV["AWS_ACCESS_KEY_ID"]
      aws_opts[:access_key_id] = ENV["AWS_ACCESS_KEY_ID"]
      aws_opts[:secret_access_key] = ENV.fetch("AWS_SECRET_ACCESS_KEY")
    end
    Aws.config.update(aws_opts)
    bucket = Aws::S3::Resource.new(region: 'eu-west-1').bucket('avnsp')

    # Build a map of member_id => most recently uploaded S3 key
    s3_files = {}
    bucket.objects(prefix: 'photos/profile-pictures/').each do |obj|
      next if obj.key.end_with?('.thumb')
      filename = File.basename(obj.key)
      if filename =~ /\A(\d+)_\d+\./
        member_id = $1.to_i
        if !s3_files[member_id] || obj.last_modified > s3_files[member_id][:last_modified]
          s3_files[member_id] = { key: obj.key, last_modified: obj.last_modified }
        end
      end
    end

    puts "Found #{s3_files.size} members with profile pictures on S3"

    changes = []
    warnings = []
    db[:members].exclude(profile_picture: nil).each do |member|
      s3_entry = s3_files[member[:id]]
      next unless s3_entry
      next if member[:profile_picture] == s3_entry[:key]

      thumb_exists = bucket.object("#{s3_entry[:key]}.thumb").exists?
      warnings << "  #{member[:id]}: missing thumbnail #{s3_entry[:key]}.thumb" unless thumb_exists
      changes << { id: member[:id], old: member[:profile_picture], new: s3_entry[:key] }
    end

    if changes.empty?
      puts "No mismatches found — nothing to fix."
      next
    end

    puts "#{changes.size} profile pictures to fix:"
    changes.each { |c| puts "  #{c[:id]}: #{c[:old]} -> #{c[:new]}" }
    unless warnings.empty?
      puts "\nWarnings (missing thumbnails):"
      warnings.each { |w| puts w }
    end

    print "\nApply these changes? [y/N] "
    next unless $stdin.gets.strip.downcase == 'y'

    changes.each do |c|
      db[:members].where(id: c[:id]).update(profile_picture: c[:new])
    end
    puts "Fixed #{changes.size} profile picture paths"
  end
end

task default: :test
