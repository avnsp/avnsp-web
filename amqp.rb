require 'bunny'
require 'json'
require 'zlib'
require 'timeout'

module Amqp
  def stop
    @consumers.each { |c| c.cancel }
    puts "#{self.class.name} stopped"
  end

  def subscribe(qname, *topics, &blk)
    raise "Topic required when subscribing" if topics.count == 0
    puts "#{qname} listening for #{topics.join(', ')}"
    ch = @conn.create_channel
    ch.prefetch 1
    t = ch.topic 'amq.topic', durable: true
    opts = {}
    if qname == ''
      opts[:auto_delete] = true
    else
      opts[:durable] = true
    end
    q = ch.queue qname, opts
    topics.each { |topic| q.bind(t, routing_key: topic) }
    c = q.subscribe(manual_ack: true, block: false) do |delivery, headers, body|
      if delivery.redelivered?
        puts "queue=#{qname} redelivered sleep=5"
        sleep 5
      end
      begin
        body = unzip(body) if headers.content_encoding == 'gzip'
        if headers.content_type != 'application/json'
          raise "Unknown Content-Type: '#{headers.content_type}'"
        end
        puts "=> #{qname} #{delivery.routing_key} #{body} #{headers}" if ENV['DEBUG']
        data = JSON.parse body, symbolize_names: true

        blk.call delivery.routing_key, data, headers
        ch.acknowledge(delivery.delivery_tag, false)
      rescue Exception => e
        puts "[ERROR] #{qname} failed to processing #{delivery.delivery_tag}: #{e.inspect}\n#{e.backtrace.join("\n")}"
        ch.reject(delivery.delivery_tag, true)
      end
    end
    @consumers << c
  end

  def publish(topic, data, opts = {})
    puts "<= #{topic} #{opts} #{data}" if ENV['DEBUG']
    ch = Thread.current[:ch] ||= @pub_conn.create_channel
    t = ch.topic 'amq.topic', durable: true
    t.publish data.to_json, opts.merge(content_type: 'application/json', routing_key: topic)
  end

  def wait_for(topic, timeout = 600, &blk)
    @conn.with_channel do |ch|
      t = ch.topic 'amq.topic', durable: true
      q = ch.queue '', exclusive: true, auto_delete: true
      q.bind(t, routing_key: topic)
      begin
        Timeout.timeout timeout do
          q.subscribe(block: true) do |d,h,p|
            data = JSON.parse(p, symbolize_names: true)
            ok = blk.call(data)
            d.consumer.cancel if ok
          end
        end
      rescue Timeout::Error
        puts "wait_for timeout"
      end
    end
  end

  private
  def unzip(body)
    StringIO.open(body) do |io|
      gz = Zlib::GzipReader.new(io)
      unzipped = gz.read
      gz.close
      unzipped
    end
  end
end


