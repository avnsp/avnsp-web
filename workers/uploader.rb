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
        version_type = content_type
        body = if version[:quality] || version[:resample] || version[:resize] || version[:format]
                 image = MiniMagick::Image.read(file)
                 # Rotate per EXIF before stripping it, so phone photos stay upright
                 # and processed copies don't carry GPS metadata.
                 image.auto_orient
                 image.strip
                 image.quality version[:quality].to_s if version[:quality]
                 image.resample version[:resample].to_s if version[:resample]
                 image.resize version[:resize].to_s if version[:resize]
                 if version[:format]
                   image.format version[:format].to_s
                   version_type = "image/#{version[:format]}"
                 end
                 image.to_blob
               else
                 file
               end

        @bucket.object(version[:path]).put(
          body:,
          content_type: version_type,
          cache_control: 'max-age=31536000'
        )
      end

      Member[data[:member_id]].update(profile_picture: data[:profile_picture]) if data[:member_id]

      publish 'photo.uploaded', data
    end

    subscribe 'file.upload', 'file.upload' do |_, data|
      file = Base64.decode64(data[:file])

      @bucket.object(data[:path]).put(
        body: file,
        content_type: data[:content_type],
        cache_control: 'max-age=31536000'
      )

      publish 'file.uploaded', data
    end

    subscribe 'file.delete', 'file.delete' do |_, data|
      # delete_objects accepts at most 1000 keys per request
      data[:keys].each_slice(1000) do |keys|
        @bucket.delete_objects(delete: { objects: keys.map { |key| { key: } } })
      end
    end
  end

  def stop
  end
end
