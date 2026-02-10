require_relative '../test_helper'

class AlbumTest < Minitest::Test
  def test_title_with_name_and_date
    album = create_album(attrs: { name: "Vårbilder", date: Date.new(2024, 5, 1) })
    assert_equal "Vårbilder - 2024-05-01", album.title
  end

  def test_title_falls_back_to_party_name_and_date
    party = create_party(name: "Vårfest", date: Date.new(2024, 5, 15))
    album = create_album(party: party, attrs: { name: nil, date: nil })
    assert_equal "Vårfest - 2024-05-15", album.title
  end

  def test_party_name
    party = create_party(name: "Höstfest")
    album = create_album(party: party)
    assert_equal "Höstfest", album.party_name
  end

  def test_party_name_nil_without_party
    member = create_member
    album = Album.create(name: "Standalone", created_by: member.id, party_id: nil)
    assert_nil album.party_name
  end

  def test_party_date
    party = create_party(date: Date.new(2024, 3, 15))
    album = create_album(party: party)
    assert_equal Date.new(2024, 3, 15), album.party_date
  end

  def test_description_returns_text
    album = create_album(attrs: { text: "Fina bilder från festen" })
    assert_equal "Fina bilder från festen", album.description
  end
end
