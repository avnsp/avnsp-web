require 'base64'
require 'mini_magick'

class Uploader
  def start
    @s3 = Aws::S3::Resource.new(region: 'eu-west-1')
    @bucket = @s3.bucket('avnsp')

    subscribe 'photo.upload', 'photo.upload' do |rk, data|
      file = Base64.decode64(data[:file])
      content_type = data[:content_type]

      data[:versions].each do |version|
        body = if version[:quality] || version[:resample] || version[:resize]
                 image = MiniMagick::Image.read(file)
                 image.quality version[:quality].to_s if version[:quality]
                 image.resample version[:resample].to_s if version[:resample]
                 image.resize version[:resize].to_s if version[:resize]
                 image.to_blob
               else
                 file
               end

        @bucket.object(version[:path]).put(
          body:,
          content_type:,
          cache_control: 'max-age=31536000'
        )
      end

      Member[data[:member_id]].update(profile_picture: data[:profile_picture]) if data[:member_id]

      publish 'photo.uploaded', data
    end
  end

  def stop
  end
end
