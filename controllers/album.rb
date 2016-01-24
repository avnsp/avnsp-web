require './controllers/base'
require "base64"

class AlbumController < BaseController
  get '/' do
    @albums = Album.order(:timestamp)
    haml :albums
  end

  get '/:album_id/:id' do |album_id, id|
    @photo = Photo[id]
    halt 404 unless @photo
    @prev_id, @next_id = @photo.surrounding_ids
    @comments = @photo.comments
    haml :photo
  end

  post '/:id/comment' do |id|
    PhotoComment.insert(member_id: @user.id,
                        photo_id: id,
                        comment: params[:comment])
    redirect back
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
