require './controllers/base'
require "base64"

class AlbumController < BaseController
  # Photos travel base64-encoded over AMQP; 10 MB stays under the broker's
  # 16 MiB default message size limit after encoding.
  MAX_PHOTO_BYTES = 10 * 1024 * 1024

  get '/' do
    @albums = Album.active.eager(:member, :party).all.sort_by(&:display_date).reverse
    haml :albums
  end

  get '/new' do
    halt 403 unless admin?
    @parties = Party.where { date <= Date.today }.order(Sequel.desc(:date)).all
    haml :album_new
  end

  post '/new' do
    halt 403 unless admin?
    name = params[:name].to_s.strip
    party = Party[params[:party_id].to_i] unless params[:party_id].to_s.empty?
    if name.empty? && party.nil?
      flash[:error] = "Ge albumet ett namn eller välj en fest."
      redirect url('/new')
    end
    album = Album.create(name: name.empty? ? nil : name,
                         text: params[:text].to_s.strip,
                         date: parse_date(params[:date]),
                         party_id: party&.id,
                         created_by: @user.id)
    redirect url("/#{album.id}")
  end

  # The trash (Papperskorg). Opening it also clears out anything that has
  # been there longer than Trash::DAYS.
  get '/trash' do
    halt 403 unless admin?
    delete_files(Trash.purge_expired!)
    @albums = Album.trashed.eager(:party).order(Sequel.desc(:deleted_at)).all
    # Photos in a trashed album are listed with the album, not on their own.
    @photos = Photo.trashed.eager(:album).order(Sequel.desc(:deleted_at)).all
                   .reject { |p| p.album&.trashed? }
    haml :album_trash
  end

  post '/trash/albums/:id/restore' do |id|
    halt 403 unless admin?
    album = Album[id]
    halt 404 unless album&.trashed?
    album.update(deleted_at: nil)
    flash[:info] = "Albumet #{album.title} har återställts."
    redirect url('/trash')
  end

  post '/trash/albums/:id/purge' do |id|
    halt 403 unless admin?
    album = Album[id]
    halt 404 unless album&.trashed?
    title = album.title
    delete_files(album.destroy_permanently)
    flash[:info] = "Albumet #{title} har raderats permanent."
    redirect url('/trash')
  end

  post '/trash/photos/:id/restore' do |id|
    halt 403 unless admin?
    photo = Photo[id]
    halt 404 unless photo&.trashed?
    photo.update(deleted_at: nil)
    flash[:info] = "Bilden har återställts."
    redirect url('/trash')
  end

  post '/trash/photos/:id/purge' do |id|
    halt 403 unless admin?
    photo = Photo[id]
    halt 404 unless photo&.trashed?
    delete_files(photo.destroy_permanently)
    flash[:info] = "Bilden har raderats permanent."
    redirect url('/trash')
  end

  get '/:album_id/:id' do |album_id, id|
    @photo = Photo[id]
    halt 404 if @photo.nil? || @photo.hidden?
    @prev_id, @next_id = @photo.surrounding_ids
    @comments = @photo.comments_dataset.eager(:member).all
    haml :photo
  end

  post '/:album_id/:id/delete' do |album_id, id|
    halt 403 unless admin?
    photo = Photo[id]
    halt 404 unless photo && photo.album_id == album_id.to_i && !photo.trashed?
    photo.update(deleted_at: Time.now)
    flash[:info] = "Bilden har flyttats till papperskorgen."
    redirect url("/#{album_id}")
  end

  post '/:id/delete' do |id|
    halt 403 unless admin?
    album = Album[id]
    halt 404 unless album && !album.trashed?
    album.update(deleted_at: Time.now)
    flash[:info] = "Albumet #{album.title} har flyttats till papperskorgen."
    redirect url('/')
  end

  post '/:id/comment' do |id|
    PhotoComment.insert(member_id: @user.id,
                        photo_id: id,
                        comment: params[:comment])
    redirect back
  end

  post '/:id/photos' do |id|
    album = Album[id]
    halt 404 unless album && !album.trashed?
    files = Array(params[:files]).select { |f| f.is_a?(Hash) && f[:tempfile] }
    captions = Array(params[:captions])
    upload_error(album, 400, "Välj minst en bild.") if files.empty?
    files.each do |f|
      unless f[:type].to_s.start_with?('image/')
        upload_error(album, 415, "#{f[:filename]} är inte en bild.")
      end
      if f[:tempfile].size > MAX_PHOTO_BYTES
        upload_error(album, 413, "#{f[:filename]} är större än 10 MB.")
      end
    end

    files.each_with_index do |f, i|
      caption = captions[i].to_s.strip
      photo = Photo.create(name: f[:filename],
                           s3_path: "photos/albums/#{album.id}",
                           caption: caption.empty? ? nil : caption,
                           album_id: album.id)
      publish('photo.upload',
              file: Base64.encode64(f[:tempfile].read),
              size: f[:tempfile].size,
              content_type: f[:type],
              versions: [
                { path: photo.path, resize: '1600x1600>', quality: 80, format: 'jpeg' },
                { path: photo.thumb_path, resize: '400x400>', quality: 75, format: 'jpeg' },
                { path: photo.original_path },
              ])
    end

    halt 201, "#{files.size}" if request.xhr?
    flash[:info] = "Bilderna kommer snart synas."
    redirect url("/#{album.id}")
  end

  get '/:id' do |id|
    @album = Album[id]
    halt 404 if @album.nil? || @album.trashed?
    @photos = @album.visible_photos
    haml :album
  end

  helpers do
    def name
      "Album"
    end

    # Only admins create and delete albums and photos; every member can upload.
    def admin?
      !!@user&.admin
    end

    def parse_date(value)
      Date.parse(value.to_s)
    rescue Date::Error
      nil
    end

    def delete_files(keys)
      publish('file.delete', keys: keys) unless keys.empty?
    end

    def upload_error(album, status, message)
      halt status, message if request.xhr?
      flash[:error] = message
      redirect url("/#{album.id}")
    end
  end
end
