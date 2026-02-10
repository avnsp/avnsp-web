require_relative '../test_helper'

class PartyControllerTest < ControllerTest
  def test_get_parties_index
    m = create_member
    login_as(m)
    create_party
    get '/party/'
    assert_equal 200, last_response.status
  end

  def test_get_party_show
    m = create_member
    login_as(m)
    p = create_party
    get "/party/#{p.id}"
    assert_equal 200, last_response.status
  end

  def test_get_attend_form
    m = create_member
    login_as(m)
    p = create_party
    get "/party/#{p.id}/attend"
    assert_equal 200, last_response.status
  end

  def test_post_attend_creates_attendance
    m = create_member
    login_as(m)
    p = create_party
    post "/party/#{p.id}/attend", {
      vegitarian: 'false',
      non_alcoholic: 'false',
      message: 'Ser fram emot det!'
    }
    assert_equal 302, last_response.status
    a = Attendance[member_id: m.id, party_id: p.id]
    assert a
    assert_equal 'Ser fram emot det!', a.message
  end

  def test_post_attend_updates_existing
    m = create_member
    login_as(m)
    p = create_party
    a = create_attendance(member: m, party: p, attrs: { message: 'Original' })
    post "/party/#{p.id}/attend", {
      vegitarian: 'true',
      non_alcoholic: 'false',
      message: 'Uppdaterat'
    }
    assert_equal 302, last_response.status
    a.reload
    assert_equal 'Uppdaterat', a.message
    assert_equal true, a.vegitarian
  end

  def test_post_attend_delete
    m = create_member
    login_as(m)
    p = create_party
    create_attendance(member: m, party: p)
    post "/party/#{p.id}/attend/delete"
    assert_equal 302, last_response.status
    assert_nil Attendance[member_id: m.id, party_id: p.id]
  end

  def test_get_buy
    m = create_member
    login_as(m)
    p = create_party
    # Ensure articles exist (seeded by migration 09)
    get "/party/#{p.id}/buy"
    assert_equal 200, last_response.status
  end

  def test_post_buy_creates_purchase
    m = create_member
    login_as(m)
    p = create_party
    article = create_article(name: "Öl")
    post "/party/#{p.id}/buy", { name: "Öl", q: "0", change: "1" }
    assert_equal 302, last_response.status
    purchase = DB[:purchases].where(party_id: p.id, member_id: m.id, article_id: article.id).first
    assert purchase
    assert_equal 1, purchase[:quantity]
  end
end
