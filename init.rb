require "aws"

FQDN = "www.academian.se"

require "sequel"
Sequel.extension :core_extensions, :pg_json, :pg_json_ops
Sequel.split_symbols = true
DB = Sequel.connect ENV["ELEPHANTSQL_URL"] || "postgres://localhost/avnsp"

require "./thumper"
TH = Thumper.new(publish_to: ENV["CLOUDAMQP_URL"] || "amqp://localhost/avnsp",
                 consume_from: ENV["CLOUDAMQP_URL"] || "amqp://localhost/avnsp")

require "./workers"
TH.register EmailWorker
TH.register EventWorker
TH.register Uploader

AWS.config(access_key_id: ENV.fetch("AWS_ACCESS_KEY_ID"),
           secret_access_key: ENV.fetch("AWS_SECRET_ACCESS_KEY"),
           region: "eu-west-1")
