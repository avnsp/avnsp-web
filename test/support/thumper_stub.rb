class ThumperStub
  attr_reader :published

  def initialize
    @published = []
    @subscriptions = {}
  end

  def publish(routing_key, data, opts = {})
    @published << { routing_key: routing_key, data: data }
  end

  def subscribe(qname, *topics, &blk)
    topics.each { |t| @subscriptions[t] = blk }
  end

  def cancel(consumer)
  end

  def simulate(topic, data)
    @subscriptions[topic]&.call(topic, data)
  end

  def reset!
    @published.clear
    @subscriptions.clear
  end
end

# Mixin for workers under test (replaces the real Amqp module)
module TestAmqp
  def subscribe(qname, *topics, &blk)
    @subscriptions ||= {}
    topics.each { |t| @subscriptions[t] = blk }
  end

  def publish(topic, data, opts = {})
    @published ||= []
    @published << { topic: topic, data: data }
  end

  def simulate(topic, data)
    @subscriptions ||= {}
    @subscriptions[topic]&.call(topic, data)
  end

  def published
    @published ||= []
  end
end
