require 'sequel'
DB = Sequel.connect ENV['ELEPHANTSQL_URL'] || 'postgres://localhost/avnsp'

require './thumper'
TH = Thumper::Base.new(publish_to: ENV['CLOUDAMQP_URL'] || 'amqp://localhost/avnsp',
                       consume_from: ENV['CLOUDAMQP_URL'] || 'amqp://localhost/avnsp')
require 'aws-sdk'
AWS.config(access_key_id: ENV.fetch("AWS_ACCESS_KEY_ID"),
           secret_access_key: ENV.fetch("AWS_SECRET_ACCESS_KEY"),
           region: 'eu-west-1')
