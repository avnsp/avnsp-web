require 'sequel'
DB = Sequel.connect 'postgres://localhost/avnsp'

require 'thumper'
TH = Thumper::Base.new(publish_to: 'amqp://localhost/avnsp',
                       consume_from: 'amqp://localhost/avnsp')
