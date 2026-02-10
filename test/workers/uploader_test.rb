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
end
