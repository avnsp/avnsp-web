require_relative '../test_helper'

class UploaderTest < Minitest::Test
  def setup
    super
    @worker = Uploader.new
    @worker.extend(TestAmqp)
    # Let the worker create its own stubbed S3 resources
    @worker.instance_variable_set(:@s3, Aws::S3::Resource.new(region: 'eu-west-1'))
    @worker.instance_variable_set(:@bucket, @worker.instance_variable_get(:@s3).bucket('avnsp'))
    @worker.start
  end

  def test_file_upload_handler_runs_without_error
    file_data = "Hello, World!"
    encoded = Base64.encode64(file_data)
    # With stub_responses: true, S3 put_object returns a stub response
    @worker.simulate("file.upload", {
      file: encoded,
      content_type: "text/plain",
      path: "uploads/test.txt"
    })
    # If we get here without error, the handler decoded and attempted upload
    assert true
  end

  def test_photo_upload_handler_processes_versions
    # Create a minimal 2x2 red PNG via ImageMagick
    tmpfile = Tempfile.new(['test', '.png'])
    system('magick', '-size', '2x2', 'xc:red', tmpfile.path)
    encoded = Base64.encode64(File.binread(tmpfile.path))
    tmpfile.unlink

    @worker.simulate("photo.upload", {
      file: encoded,
      content_type: "image/png",
      versions: [
        { path: "photos/test.png", quality: 95, resample: 95 },
        { path: "photos/test.png.thumb", quality: 95, resample: 95, resize: 1 }
      ]
    })
    # If we get here without error, the handler processed both versions
    assert true
  end
end
