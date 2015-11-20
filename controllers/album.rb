require './controllers/base'
require "base64"

class AlbumController < BaseController
  get '/' do
    @albums = Album.order(:timestamp)
    haml :albums
  end

  get '/:uuid/:name' do |uuid, name|
    s3 = AWS::S3.new
    objects = s3.buckets['avnsp'].objects
    img = objects["avnsp/#{uuid}/#{name}"]
    content_type img.content_type
    img.read
  end

  post '/' do
    params[:files].each_with_index do |f, i|
      tempfile = f[:tempfile]
      size = tempfile.size
      file = tempfile.read
      caption = params[:captions][i]
      photo = Photo.create(name: f[:filename],
                           s3_path: "photos",
                           caption: caption,
                           member_id: session[:id],
                           event_id: params[:event_id])
      publish('photo.upload',
              file: Base64.encode64(file),
              size: size,
              content_type: f[:type],
              versions: [
                { path: photo[:path], quality: 75, resample: 72 },
                { path: photo[:thumb_path], quality: 75, resample: 72, resize: '100' },
                { path: photo[:original_path] },
              ])
    end
    flash[:info] = "Bilderna kommer snart synas."
    redirect back
  end

  get '/:id' do |id|
    @album = Album[id]
    @photos = @album.photos
    haml :album
  end

  helpers do
    def name
      "Album"
    end
  end
end
