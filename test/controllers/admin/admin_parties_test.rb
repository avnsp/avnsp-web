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

  def test_show_party_shows_send_invitations_with_confirmation
    admin = create_admin
    login_as(admin)
    p = create_party(name: "Höstfest")
    get "/cheferiet/parties/#{p.id}"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "/cheferiet/parties/#{p.id}/send-invitations"
    assert_includes last_response.body, "Skicka inbjudningarna!"
    assert_includes last_response.body, "invitation-confirmation"
    assert_includes last_response.body, "/js/admin-invitations.js"
    assert_includes last_response.body, "Ja, skicka inbjudningarna"
  end

  def test_invitation_greets_by_nick_or_first_name
    login_as(create_admin)
    p = create_party(price: 600)
    with_nick = create_member(first_name: "Therese", nick: "Teto", email: "teto@academian.se")
    empty_nick = create_member(first_name: "Alessandra", nick: "", email: "ale@academian.se")
    no_nick = create_member(first_name: "Erik", nick: nil, email: "erik@academian.se")
    [with_nick, empty_nick, no_nick].each { |m| create_transaction(member: m, sum: 100) }
    post "/cheferiet/parties/#{p.id}/send-invitations"
    greetings = TH.published.select { |x| x[:routing_key] == 'send-invitations' }
                  .to_h { |x| [x[:data][:email], x[:data][:nick]] }
    assert_equal "Teto", greetings["teto@academian.se"]
    assert_equal "Alessandra", greetings["ale@academian.se"]
    assert_equal "Erik", greetings["erik@academian.se"]
  end

  def test_new_party_form_does_not_show_send_invitations
    admin = create_admin
    login_as(admin)
    get '/cheferiet/parties/new'
    assert_equal 200, last_response.status
    refute_includes last_response.body, "send-invitations"
    refute_includes last_response.body, "Skicka inbjudningarna!"
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

  def test_party_pages_link_back_to_party
    admin = create_admin
    login_as(admin)
    p = create_party(name: "Vårfest")
    %w[attendance emails member_article_list snaps_lottery].each do |page|
      get "/cheferiet/parties/#{p.id}/#{page}"
      assert_equal 200, last_response.status, page
      assert_match %r{href='[^']*/cheferiet/parties/#{p.id}'}, last_response.body, page
      assert_includes last_response.body, "Tillbaka till Vårfest", page
    end
  end

  def test_party_page_links_back_to_party_list
    admin = create_admin
    login_as(admin)
    p = create_party
    get "/cheferiet/parties/#{p.id}"
    assert_equal 200, last_response.status
    assert_match %r{href='[^']*/cheferiet/parties/'>← Tillbaka till alla fester}, last_response.body
  end

  def test_snaps_lottery_hides_empty_nick
    admin = create_admin
    login_as(admin)
    p = create_party
    create_attendance(member: create_member(first_name: "Anna", last_name: "Berg", nick: ""), party: p)
    get "/cheferiet/parties/#{p.id}/snaps_lottery"
    assert_includes last_response.body, "Anna Berg"
    refute_includes last_response.body, '""'
  end

  def test_admin_missing_party_returns_404
    login_as(create_admin)
    get "/cheferiet/parties/999999"
    assert_equal 404, last_response.status
  end

  def test_party_page_for_missing_party_returns_404
    admin = create_admin
    login_as(admin)
    get "/cheferiet/parties/999999/attendance"
    assert_equal 404, last_response.status
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
    post "/cheferiet/parties/attendance/#{a.id}/delete"
    assert_equal 302, last_response.status
    assert_nil DB[:attendances].where(id: a.id).first
  end

  def test_delete_attendance_removes_right_foot
    admin = create_admin
    login_as(admin)
    a = create_attendance
    a.add_right_foot('name' => 'Högerfot')
    post "/cheferiet/parties/attendance/#{a.id}/delete"
    assert_equal 302, last_response.status
    assert_nil DB[:attendances].where(id: a.id).first
    assert_nil DB[:right_feet].where(attendance_id: a.id).first
  end

  def test_delete_attendance_without_referer_redirects_to_party_list
    admin = create_admin
    login_as(admin)
    a = create_attendance
    post "/cheferiet/parties/attendance/#{a.id}/delete"
    assert_equal 302, last_response.status
    assert_match %r{/cheferiet/parties/$}, last_response.location
  end

  def test_delete_attendance_forbidden_for_non_admin
    m = create_member
    login_as(m)
    a = create_attendance
    post "/cheferiet/parties/attendance/#{a.id}/delete"
    assert_equal 403, last_response.status
    assert DB[:attendances].where(id: a.id).first
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
