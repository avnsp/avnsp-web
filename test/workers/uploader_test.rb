require_relative '../test_helper'

class UploaderTest < Minitest::Test
  def setup
    super
    @worker = Uploader.new
    @worker.extend(TestAmqp)
    @worker.instance_variable_set(:@s3, Aws::S3::Resource.new(region: 'eu-west-1'))
    @worker.instance_variable_set(:@bucket, @worker.instance_variable_get(:@s3).bucket('avnsp'))
    @worker.start
  end

  def test_photo_upload_with_versions
    file_data = File.read("test/fixtures/tiny.jpg", mode: "rb")
    encoded = Base64.encode64(file_data)
    @worker.simulate("photo.upload", {
      file: encoded,
      content_type: "image/jpeg",
      versions: [
        { path: "photos/test.jpg", quality: 75, resample: 72 },
        { path: "photos/test.thumb.jpg", quality: 75, resample: 72, resize: "100" }
      ]
    })
    assert @worker.published.any? { |p| p[:topic] == "photo.uploaded" }
  end

  def test_photo_upload_raw_version
    file_data = File.read("test/fixtures/tiny.jpg", mode: "rb")
    encoded = Base64.encode64(file_data)
    @worker.simulate("photo.upload", {
      file: encoded,
      content_type: "image/jpeg",
      versions: [
        { path: "photos/original.jpg" }
      ]
    })
    assert @worker.published.any? { |p| p[:topic] == "photo.uploaded" }
  end

  def test_photo_upload_updates_member_profile_picture
    member = create_member
    file_data = File.read("test/fixtures/tiny.jpg", mode: "rb")
    encoded = Base64.encode64(file_data)
    path = "photos/profile-pictures/#{member.id}_123.jpeg"
    @worker.simulate("photo.upload", {
      file: encoded,
      content_type: "image/jpeg",
      member_id: member.id,
      profile_picture: path,
      versions: [
        { path: path, quality: 95, resample: 95 },
        { path: "#{path}.thumb", quality: 95, resample: 95, resize: 112 }
      ]
    })
    assert_equal path, Member[member.id].profile_picture
  end
end
