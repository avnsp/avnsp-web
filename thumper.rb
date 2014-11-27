require './amqp'

class Thumper
  include Amqp

  def initialize opts = {}
    @conn = Bunny.new(opts[:consume_from])
    @conn.start
    @pub_conn = Bunny.new(opts[:publish_to])
    @pub_conn.start
    @workers = []
  end

  def register worker_class
    worker_class.include Amqp
    w = worker_class.new
    w.instance_variable_set '@conn', @conn
    w.instance_variable_set '@pub_conn', @pub_conn
    w.instance_variable_set '@consumers', []
    w.start
    @workers << w
  end
end
