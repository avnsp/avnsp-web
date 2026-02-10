# frozen_string_literal: true

require "aws-sdk-s3"

FQDN = "avnsp.herokuapp.com"

require "sequel"
Sequel.extension :core_extensions, :pg_json, :pg_json_ops
DB = Sequel.connect ENV["ELEPHANTSQL_URL"] || "postgres://localhost/avnsp"

require "./thumper"
TH = Thumper.new(publish_to: ENV["CLOUDAMQP_URL"] || "amqp://localhost/avnsp",
                 consume_from: ENV["CLOUDAMQP_URL"] || "amqp://localhost/avnsp")

require "./workers"
TH.register EmailWorker
TH.register EventWorker
TH.register Uploader

aws_opts = { region: "eu-west-1" }
if ENV["AWS_ACCESS_KEY_ID"]
  aws_opts[:access_key_id] = ENV["AWS_ACCESS_KEY_ID"]
  aws_opts[:secret_access_key] = ENV.fetch("AWS_SECRET_ACCESS_KEY")
end
Aws.config.update(aws_opts)
