require 'zlib'
require 'base64'
require 'mini_magick'

class PhotoUploader
  def start
    subscribe 'photo.upload', 'photo.upload' do |rk, data|
      s3 = AWS::S3.new
      filename = data[:name]
      file = Base64.decode64(data[:file])

      image = MiniMagick::Image.read(file)
      image.quality 75
      image.resample 72

      objects = s3.buckets['avnsp'].objects

      ct = image.mime_type
      image.write filename
      objects["avnsp/#{data[:path]}"].write(:data => image.to_blob, :content_type => ct, cache_control: 'max-age=31536000')
      objects["avnsp/#{data[:original_path]}"].write(:data => image.to_blob, :content_type => ct, cache_control: 'max-age=31536000')

      thumb = image.dup
      thumb.resize '100'
      thumb.quality 75
      thumb.resample 72
      objects["avnsp/#{data[:thumb_path]}"].write(:data => thumb.to_blob, :content_type => ct, cache_control: 'max-age=31536000')
      image.write filename.sub('.jpg', '.thumb.jpg')

      publish 'photo.uploaded', data
    end
  end

  def stop
  end
end

