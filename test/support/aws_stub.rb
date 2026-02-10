module Aws
  module S3
    class Client
      def initialize(**opts)
        @objects = {}
      end

      def put_object(bucket:, key:, **opts)
        @objects[key] = opts.merge(bucket: bucket)
      end

      def get_object(bucket:, key:)
        data = @objects[key]
        raise Errors::NoSuchKey.new(nil, "NoSuchKey") unless data
        { content_type: data[:content_type] || "application/octet-stream",
          body: StringIO.new(data[:body] || "") }
      end
    end

    class Resource
      def initialize(**opts)
        @buckets = {}
      end

      def bucket(name)
        @buckets[name] ||= BucketStub.new(name)
      end
    end

    class BucketStub
      attr_reader :name

      def initialize(name)
        @name = name
        @objects = {}
      end

      def object(key)
        @objects[key] ||= ObjectStub.new(key)
      end
    end

    class ObjectStub
      attr_reader :key
      attr_accessor :body, :content_type

      def initialize(key)
        @key = key
      end

      def put(body:, content_type: nil, **opts)
        @body = body
        @content_type = content_type
      end

      def get
        { body: StringIO.new(@body || ""), content_type: @content_type }
      end
    end

    module Errors
      class NoSuchKey < StandardError; end
    end
  end
end
