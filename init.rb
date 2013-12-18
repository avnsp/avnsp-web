require 'sequel'
DB = Sequel.connect 'postgres://localhost/avnsp'

require 'thumper'
TH = Thumper::Base.new(publish_to: 'amqp://localhost/avnsp',
                       consume_from: 'amqp://localhost/avnsp')
require 'aws-sdk'
AWS.config(access_key_id: ENV.fetch("AWS_ACCESS_KEY_ID"),
           secret_access_key: ENV.fetch("AWS_SECRET_ACCESS_KEY"),
           region: 'eu-west-1')
