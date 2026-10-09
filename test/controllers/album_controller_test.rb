require_relative '../test_helper'

class AlbumControllerTest < ControllerTest
  def test_get_albums_index
    m = create_member
    login_as(m)
    get '/album/'
    assert_equal 200, last_response.status
  end

  def test_get_album_show
    m = create_member
    login_as(m)
    album = create_album(member: m)
    get "/album/#{album.id}"
    assert_equal 200, last_response.status
  end

  def test_get_photo_show
    m = create_member
    login_as(m)
    album = create_album(member: m)
    photo = create_photo(album: album)
    get "/album/#{album.id}/#{photo.id}"
    assert_equal 200, last_response.status
  end

  def test_get_photo_404
    m = create_member
    login_as(m)
    get "/album/1/99999"
    assert_equal 404, last_response.status
  end

  def test_post_comment
    m = create_member
    login_as(m)
    album = create_album(member: m)
    photo = create_photo(album: album)
    post "/album/#{photo.id}/comment", { comment: "Fin bild!" },
         'HTTP_REFERER' => "/album/#{album.id}/#{photo.id}"
    assert_equal 302, last_response.status
    c = PhotoComment.where(photo_id: photo.id).first
    assert c
    assert_equal "Fin bild!", c.comment
  end

  def test_get_album_404
    login_as(create_member)
    get "/album/99999"
    assert_equal 404, last_response.status
  end

  def test_albums_index_lists_newest_first
    m = create_member
    login_as(m)
    create_album(member: m, attrs: { name: "Gammalt", date: Date.new(2003, 5, 23) })
    create_album(member: m, attrs: { name: "Nytt", date: Date.new(2026, 5, 1) })
    create_album(member: m, attrs: { name: "Mitten", date: Date.new(2012, 2, 11) })
    get '/album/'
    body = last_response.body
    assert body.index("Nytt") < body.index("Mitten")
    assert body.index("Mitten") < body.index("Gammalt")
  end

  def test_get_new_album_page
    login_as(create_admin)
    create_party(name: "Gamla vårfesten", date: Date.today - 400, attendance_deadline: Date.today - 410)
    create_party(name: "Kommande höstfest")
    get '/album/new'
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Gamla vårfesten"
    refute_includes last_response.body, "Kommande höstfest"
  end

  def test_back_links
    m = create_member
    login_as(m)
    album = create_album(member: m)
    photo = create_photo(album: album)
    get "/album/#{album.id}"
    assert_match %r{/album/['"]>&#8592; Gå tillbaka<}, last_response.body
    get "/album/#{album.id}/#{photo.id}"
    assert_match %r{/album/#{album.id}['"]>&#8592; Gå tillbaka till albumet<}, last_response.body
    login_as(create_admin)
    get "/album/new"
    assert_match %r{/album/['"]>&#8592; Gå tillbaka<}, last_response.body
  end

  def test_album_and_party_pages_link_to_each_other
    m = create_member
    login_as(m)
    party = create_party(name: "Höstfest")
    album = create_album(member: m, party: party)
    get "/album/#{album.id}"
    assert_match %r{href=['"]/party/#{party.id}['"]}, last_response.body
    get "/party/#{party.id}"
    assert_match %r{href=['"]/album/#{album.id}['"]}, last_response.body
    assert_includes last_response.body, album.title
  end

  def test_members_cannot_create_albums
    login_as(create_member)
    get '/album/'
    refute_includes last_response.body, "Skapa nytt album"
    get '/album/new'
    assert_equal 403, last_response.status
    post "/album/new", { name: "Vårbal" }
    assert_equal 403, last_response.status
    assert_equal 0, Album.count
  end

  def test_create_album
    m = create_admin
    login_as(m)
    get '/album/'
    assert_includes last_response.body, "Skapa nytt album"
    post "/album/new", { name: "Vårbal", date: "2026-05-01", text: "Bilder från balen" }
    album = Album.where(name: "Vårbal").first
    assert album
    assert_equal m.id, album.created_by
    assert_equal Date.new(2026, 5, 1), album.date
    assert_equal 302, last_response.status
    assert_match %r{/album/#{album.id}$}, last_response.location
  end

  def test_create_album_for_party_without_name
    login_as(create_admin)
    party = create_party
    post "/album/new", { party_id: party.id }
    album = Album.where(party_id: party.id).first
    assert album
    assert_nil album.name
  end

  def test_create_album_requires_name_or_party
    login_as(create_admin)
    post "/album/new", { name: " " }
    assert_equal 0, Album.count
    assert_equal 302, last_response.status
    assert_match %r{/album/new$}, last_response.location
  end

  def test_upload_photos_creates_rows_and_publishes
    m = create_member
    login_as(m)
    album = create_album(member: m)
    files = [photo_file, photo_file]
    post "/album/#{album.id}/photos", { files: files, captions: ["Skål", ""] }
    assert_equal 302, last_response.status

    photos = Photo.where(album_id: album.id).order(:id).all
    assert_equal 2, photos.size
    assert_equal "Skål", photos[0].caption
    assert_nil photos[1].caption
    assert photos.all?(&:resized?)

    msgs = TH.published.select { |p| p[:routing_key] == 'photo.upload' }
    assert_equal 2, msgs.size
    paths = msgs[0][:data][:versions].map { |v| v[:path] }
    assert_equal [photos[0].path, photos[0].thumb_path, photos[0].original_path], paths
  end

  def test_upload_photos_xhr_returns_created
    m = create_member
    login_as(m)
    album = create_album(member: m)
    post "/album/#{album.id}/photos", { files: [photo_file] }, 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest'
    assert_equal 201, last_response.status
    assert_equal 1, Photo.where(album_id: album.id).count
  end

  def test_upload_rejects_non_images
    m = create_member
    login_as(m)
    album = create_album(member: m)
    file = Rack::Test::UploadedFile.new(StringIO.new(+"hej"), "text/plain", original_filename: "a.txt")
    post "/album/#{album.id}/photos", { files: [file] }, 'HTTP_X_REQUESTED_WITH' => 'XMLHttpRequest'
    assert_equal 415, last_response.status
    assert_equal 0, Photo.where(album_id: album.id).count
    assert_empty TH.published
  end

  def test_upload_to_missing_album
    login_as(create_member)
    post "/album/99999/photos", { files: [photo_file] }
    assert_equal 404, last_response.status
  end

  def test_deleting_album_moves_it_to_trash
    admin = create_admin
    login_as(admin)
    album = create_album(attrs: { name: "Raderat album" })
    photo = create_photo(album: album)
    PhotoComment.insert(member_id: admin.id, photo_id: photo.id, comment: "Snygg")
    post "/album/#{album.id}/delete"
    assert_equal 302, last_response.status
    assert Album[album.id].trashed?
    assert Photo[photo.id]
    assert_equal 1, PhotoComment.where(photo_id: photo.id).count
    assert_empty TH.published

    follow_redirect!
    assert_includes last_response.body, "har flyttats till papperskorgen"
    refute_match %r{/album/#{album.id}['"]}, last_response.body
    get "/album/#{album.id}"
    assert_equal 404, last_response.status
    get "/album/#{album.id}/#{photo.id}"
    assert_equal 404, last_response.status
    get "/party/#{album.party_id}"
    refute_includes last_response.body, "Raderat album"
  end

  def test_trash_lists_and_restores_album
    login_as(create_admin)
    album = create_album(attrs: { name: "Raderat album", deleted_at: Time.now })
    get '/album/trash'
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Raderat album"
    post "/album/trash/albums/#{album.id}/restore"
    refute Album[album.id].trashed?
    get "/album/#{album.id}"
    assert_equal 200, last_response.status
  end

  def test_trash_purges_album_permanently
    admin = create_admin
    login_as(admin)
    album = create_album(attrs: { deleted_at: Time.now })
    photo = create_photo(album: album)
    PhotoComment.insert(member_id: admin.id, photo_id: photo.id, comment: "Snygg")
    post "/album/trash/albums/#{album.id}/purge"
    assert_nil Album[album.id]
    assert_nil Photo[photo.id]
    assert_equal 0, PhotoComment.where(photo_id: photo.id).count
    msg = TH.published.find { |p| p[:routing_key] == 'file.delete' }
    assert_equal photo.s3_keys, msg[:data][:keys]
  end

  def test_cannot_purge_album_that_is_not_in_trash
    login_as(create_admin)
    album = create_album
    post "/album/trash/albums/#{album.id}/purge"
    assert_equal 404, last_response.status
    assert Album[album.id]
  end

  def test_opening_trash_purges_items_older_than_30_days
    login_as(create_admin)
    old_album = create_album(attrs: { deleted_at: Time.now - 31 * 24 * 3600 })
    old_photo = create_photo(album: create_album, attrs: { deleted_at: Time.now - 31 * 24 * 3600 })
    recent = create_album(attrs: { deleted_at: Time.now - 29 * 24 * 3600 })
    get '/album/trash'
    assert_nil Album[old_album.id]
    assert_nil Photo[old_photo.id]
    assert Album[recent.id]
    msg = TH.published.find { |p| p[:routing_key] == 'file.delete' }
    assert_includes msg[:data][:keys], old_photo.path
  end

  def test_members_cannot_use_trash
    login_as(create_member)
    album = create_album(attrs: { deleted_at: Time.now })
    get '/album/trash'
    assert_equal 403, last_response.status
    post "/album/trash/albums/#{album.id}/restore"
    assert_equal 403, last_response.status
    post "/album/trash/albums/#{album.id}/purge"
    assert_equal 403, last_response.status
    assert Album[album.id].trashed?
  end

  def test_cannot_upload_to_trashed_album
    login_as(create_member)
    album = create_album(attrs: { deleted_at: Time.now })
    post "/album/#{album.id}/photos", { files: [photo_file] }
    assert_equal 404, last_response.status
  end

  def test_member_cannot_delete_album_even_their_own
    m = create_member
    album = create_album(member: m)
    login_as(m)
    post "/album/#{album.id}/delete"
    assert_equal 403, last_response.status
    assert Album[album.id]
    assert_empty TH.published
  end

  def test_deleting_photo_moves_it_to_trash
    login_as(create_admin)
    album = create_album
    photo = create_photo(album: album, attrs: { caption: "Raderad bild" })
    other = create_photo(album: album)
    post "/album/#{album.id}/#{photo.id}/delete"
    assert_equal 302, last_response.status
    assert_match %r{/album/#{album.id}$}, last_response.location
    assert Photo[photo.id].trashed?
    refute Photo[other.id].trashed?
    assert_empty TH.published
    get "/album/#{album.id}/#{photo.id}"
    assert_equal 404, last_response.status
    get "/album/#{album.id}"
    refute_includes last_response.body, "Raderad bild"
    get '/album/trash'
    assert_includes last_response.body, "Raderad bild"
  end

  def test_trash_restores_and_purges_photo
    login_as(create_admin)
    album = create_album
    restored = create_photo(album: album, attrs: { deleted_at: Time.now })
    purged = create_photo(album: album, attrs: { deleted_at: Time.now })
    post "/album/trash/photos/#{restored.id}/restore"
    refute Photo[restored.id].trashed?
    post "/album/trash/photos/#{purged.id}/purge"
    assert_nil Photo[purged.id]
    msg = TH.published.find { |p| p[:routing_key] == 'file.delete' }
    assert_equal purged.s3_keys, msg[:data][:keys]
  end

  def test_member_cannot_delete_photo
    photo = create_photo
    login_as(create_member)
    post "/album/#{photo.album_id}/#{photo.id}/delete"
    assert_equal 403, last_response.status
    assert Photo[photo.id]
  end

  def test_delete_buttons_only_shown_to_admins
    m = create_member
    album = create_album(member: m)
    photo = create_photo(album: album)
    login_as(m)
    get "/album/#{album.id}"
    refute_includes last_response.body, "Ta bort album"
    assert_includes last_response.body, "Ladda upp bilder"
    get "/album/#{album.id}/#{photo.id}"
    refute_includes last_response.body, "Ta bort bild"
    get '/album/'
    refute_includes last_response.body, "Papperskorg"
    login_as(create_admin)
    get '/album/'
    assert_includes last_response.body, "Papperskorg"
    get "/album/#{album.id}"
    assert_includes last_response.body, "Ta bort album"
    get "/album/#{album.id}/#{photo.id}"
    assert_includes last_response.body, "Ta bort bild"
  end

  private

  def photo_file
    Rack::Test::UploadedFile.new("test/fixtures/tiny.jpg", "image/jpeg")
  end
end
