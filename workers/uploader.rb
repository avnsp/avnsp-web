require 'zlib'
require 'base64'
require 'mini_magick'

class Uploader
  def start
    @s3 = AWS::S3.new(region: 'eu-west-1')

    subscribe 'file.upload', 'file.upload' do |rk, data|
      file = Base64.decode64(data[:file])
      ct = data[:content_type]
      objects = @s3.buckets['avnsp'].objects
      object = {
        data: file,
        content_type: ct,
        cache_control: 'max-age=31536000'
      }
      objects[data[:path]].write(object)
    end

    subscribe 'photo.upload', 'photo.upload' do |rk, data|
      file = Base64.decode64(data[:file])
      image = MiniMagick::Image.read(file)
      data[:versions].each do |v|
        i = image.dup
        i.combine_options do |b|
          b.quality(v[:quality]) if v[:quality]
          b.resample(v[:resample]) if v[:resample]
          b.resize(v[:resize]) if v[:resize]
        end

        ct = i.mime_type
        objects = @s3.buckets['avnsp'].objects
        object = {
          data: i.to_blob,
          content_type: ct,
          cache_control: 'max-age=31536000'
        }
        objects[v[:path]].write(object)
      end

      publish 'photo.uploaded', data
    end
  end

  def stop
  end
end

