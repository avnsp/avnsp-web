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
end
