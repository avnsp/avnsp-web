require_relative '../test_helper'

class PhotoTest < Minitest::Test
  def test_s3_path_setter_generates_uuid_paths
    album = create_album
    photo = Photo.new(name: "test.jpg", album_id: album.id)
    photo.s3_path = "photos/album1"
    assert_match %r{^photos/album1/[a-f0-9\-]+\.jpg$}, photo.path
    assert_match %r{^photos/album1/[a-f0-9\-]+\.thumb\.jpg$}, photo.thumb_path
    assert_match %r{^photos/album1/[a-f0-9\-]+\.orig\.jpg$}, photo.original_path
  end

  def test_s3_path_setter_paths_share_same_uuid
    album = create_album
    photo = Photo.new(name: "test.jpg", album_id: album.id)
    photo.s3_path = "photos"
    uuid = photo.path.match(/([a-f0-9\-]{36})\.jpg$/)[1]
    assert_includes photo.thumb_path, uuid
    assert_includes photo.original_path, uuid
  end

  def test_thumb_temp
    photo = create_photo(attrs: { thumb_path: "photos/abc.thumb.jpg" })
    assert_equal "https://www.academian.se/photos/abc.thumb.jpg", photo.thumb_temp
  end

  def test_file_temp
    photo = create_photo(attrs: { path: "photos/abc.jpg" })
    assert_equal "https://www.academian.se/photos/abc.jpg", photo.file_temp
  end

  def test_original_temp
    photo = create_photo(attrs: { original_path: "photos/abc.orig.jpg" })
    assert_equal "https://www.academian.se/photos/abc.orig.jpg", photo.original_temp
  end

  def test_surrounding_ids_middle
    album = create_album
    p1 = create_photo(album: album)
    p2 = create_photo(album: album)
    p3 = create_photo(album: album)
    ids = p2.surrounding_ids
    assert_includes ids, p1.id
    assert_includes ids, p3.id
    refute_includes ids, p2.id
  end

  def test_surrounding_ids_first
    album = create_album
    p1 = create_photo(album: album)
    p2 = create_photo(album: album)
    # For the first photo, surrounding wraps around (index -1 goes to last)
    ids = p1.surrounding_ids
    assert_includes ids, p2.id
  end
end
