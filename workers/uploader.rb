require 'zlib'
require 'base64'
require 'mini_magick'

class Uploader
  def start
    @s3 = Aws::S3::Resource.new(region: 'eu-west-1')
    @bucket = @s3.bucket('avnsp')

    subscribe 'file.upload', 'file.upload' do |rk, data|
      file = Base64.decode64(data[:file])
      ct = data[:content_type]
      @bucket.object(data[:path]).put(
        body: file,
        content_type: ct,
        cache_control: 'max-age=31536000'
      )
    end

    subscribe 'photo.upload', 'photo.upload' do |rk, data|
      raw = Base64.decode64(data[:file])
      ct = data[:content_type]

      data[:versions].each do |v|
        image = MiniMagick::Image.read(raw)
        image.resize "#{v[:resize]}x#{v[:resize]}" if v[:resize]
        image.quality v[:quality].to_s if v[:quality]
        image.sampling_factor v[:resample].to_s if v[:resample]

        @bucket.object(v[:path]).put(
          body: image.to_blob,
          content_type: ct,
          cache_control: 'max-age=31536000'
        )
      end
    end
  end

  def stop
  end
end
