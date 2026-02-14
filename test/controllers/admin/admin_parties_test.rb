require_relative '../../test_helper'

class AdminPartiesTest < ControllerTest
  def test_non_admin_gets_403
    m = create_member(admin: false)
    login_as(m)
    get '/cheferiet/parties/'
    assert_equal 403, last_response.status
  end

  def test_index_lists_parties
    admin = create_admin
    login_as(admin)
    create_party(name: "Vårfest 2024")
    get '/cheferiet/parties/'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Vårfest 2024'
  end

  def test_new_party_form
    admin = create_admin
    login_as(admin)
    get '/cheferiet/parties/new'
    assert_equal 200, last_response.status
  end

  def test_show_party
    admin = create_admin
    login_as(admin)
    p = create_party(name: "Höstfest")
    get "/cheferiet/parties/#{p.id}"
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Höstfest'
  end

  def test_attendance_page
    admin = create_admin
    login_as(admin)
    p = create_party
    m = create_member
    create_attendance(member: m, party: p)
    get "/cheferiet/parties/#{p.id}/attendance"
    assert_equal 200, last_response.status
  end

  def test_emails_page
    admin = create_admin
    login_as(admin)
    p = create_party
    m = create_member(email: "test@academian.se")
    create_attendance(member: m, party: p)
    get "/cheferiet/parties/#{p.id}/emails"
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'test@academian.se'
  end

  def test_member_article_list_page
    admin = create_admin
    login_as(admin)
    p = create_party
    get "/cheferiet/parties/#{p.id}/member_article_list"
    assert_equal 200, last_response.status
  end

  def test_snaps_lottery_page
    admin = create_admin
    login_as(admin)
    p = create_party
    get "/cheferiet/parties/#{p.id}/snaps_lottery"
    assert_equal 200, last_response.status
  end

  def test_invalid_page_returns_403
    admin = create_admin
    login_as(admin)
    p = create_party
    get "/cheferiet/parties/#{p.id}/evil_page"
    assert_equal 403, last_response.status
  end

  def test_post_attendance
    admin = create_admin
    login_as(admin)
    p = create_party
    m = create_member
    post "/cheferiet/parties/#{p.id}/attendance", {
      member_id: m.id,
      vegitarian: 'false',
      non_alcoholic: 'false'
    }
    assert_equal 302, last_response.status
    a = DB[:attendances].where(party_id: p.id, member_id: m.id).first
    assert a
  end

  def test_post_attendance_without_member_returns_403
    admin = create_admin
    login_as(admin)
    p = create_party
    post "/cheferiet/parties/#{p.id}/attendance", {}
    assert_equal 403, last_response.status
  end

  def test_delete_attendance
    admin = create_admin
    login_as(admin)
    p = create_party
    m = create_member
    a = create_attendance(member: m, party: p)
    delete "/cheferiet/parties/attendance/#{a.id}"
    assert_equal 302, last_response.status
    assert_nil DB[:attendances].where(id: a.id).first
  end

  def test_update_party
    admin = create_admin
    login_as(admin)
    create_booking_account(number: 4001)
    p = create_party(name: "Old Name")
    post "/cheferiet/parties/#{p.id}", {
      name: 'Updated',
      type: 'vf',
      date: (Date.today + 7).to_s,
      attendance_deadline: (Date.today + 5).to_s,
      'organizers[]' => ''
    }
    assert_equal 302, last_response.status
    updated = DB[:parties].where(id: p.id).first
    assert_equal 'Updated', updated[:name]
  end
end
