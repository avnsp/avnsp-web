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
  end

  def stop
  end
end
