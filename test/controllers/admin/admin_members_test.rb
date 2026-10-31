require_relative '../../test_helper'

class AdminMembersTest < ControllerTest
  def test_non_admin_gets_403
    m = create_member(admin: false)
    login_as(m)
    get '/cheferiet/members/'
    assert_equal 403, last_response.status
  end

  def test_index_lists_members
    admin = create_admin
    login_as(admin)
    create_member(first_name: "Anna", last_name: "Andersson")
    get '/cheferiet/members/'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Andersson, Anna'
  end

  def test_new_member_form
    admin = create_admin
    login_as(admin)
    get '/cheferiet/members/new'
    assert_equal 200, last_response.status
  end

  def test_create_member
    admin = create_admin
    login_as(admin)
    post '/cheferiet/members/new', {
      first_name: 'Nils',
      last_name: 'Nilsson',
      email: 'nils@academian.se',
      studied: 'F',
      started: '2020'
    }
    assert_equal 302, last_response.status
    m = DB[:members].where(email: 'nils@academian.se').first
    assert m
    assert_equal 'Nils', m[:first_name]
  end

  def test_show_member
    admin = create_admin
    login_as(admin)
    m = create_member(first_name: "Kalle", last_name: "Karlsson")
    get "/cheferiet/members/#{m.id}"
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Kalle'
  end

  def test_member_page_links_back_to_member_list
    admin = create_admin
    login_as(admin)
    m = create_member
    get "/cheferiet/members/#{m.id}"
    assert_equal 200, last_response.status
    assert_match %r{href='[^']*/cheferiet/members/'>← Tillbaka till alla medlemmar}, last_response.body
  end

  def test_new_member_page_shows_heading
    admin = create_admin
    login_as(admin)
    get "/cheferiet/members/new"
    assert_includes last_response.body, "Ny medlem"
  end

  def test_update_member_with_blank_nick_saves_no_nick
    admin = create_admin
    login_as(admin)
    m = create_member(nick: "Gammalt")
    post "/cheferiet/members/#{m.id}", { first_name: 'Erik', last_name: 'Svensson', nick: '  ' }
    assert_nil DB[:members].where(id: m.id).get(:nick)
  end

  def test_missing_member_returns_404
    login_as(create_admin)
    get "/cheferiet/members/999999"
    assert_equal 404, last_response.status
  end

  def test_send_password_reset_emails_member_and_keeps_password
    login_as(create_admin)
    m = create_member(email: "glomsk@academian.se")
    m.password = "oldpass"
    m.save
    post "/cheferiet/members/#{m.id}/send-password-reset"
    assert_equal 302, last_response.status
    msg = TH.published.find { |x| x[:routing_key] == 'member.reset-password' }
    assert_equal "glomsk@academian.se", msg[:data][:email]
    assert Member[m.id].password == "oldpass"
  end

  def test_send_password_reset_requires_admin
    login_as(create_member(admin: false))
    m = create_member
    post "/cheferiet/members/#{m.id}/send-password-reset"
    assert_equal 403, last_response.status
    refute TH.published.any? { |x| x[:routing_key] == 'member.reset-password' }
  end

  def test_send_password_reset_missing_member_returns_404
    login_as(create_admin)
    post "/cheferiet/members/999999/send-password-reset"
    assert_equal 404, last_response.status
  end

  def test_send_password_reset_skips_member_without_email
    login_as(create_admin)
    m = create_member(email: "")
    post "/cheferiet/members/#{m.id}/send-password-reset"
    assert_equal 302, last_response.status
    refute TH.published.any? { |x| x[:routing_key] == 'member.reset-password' }
  end

  def test_member_page_has_password_button_but_new_page_does_not
    login_as(create_admin)
    m = create_member
    get "/cheferiet/members/#{m.id}"
    assert_includes last_response.body, "/cheferiet/members/#{m.id}/send-password-reset"
    get "/cheferiet/members/new"
    refute_includes last_response.body, "send-password-reset"
  end

  def test_update_member
    admin = create_admin
    login_as(admin)
    m = create_member(first_name: "Old", last_name: "Name")
    post "/cheferiet/members/#{m.id}", {
      first_name: 'New',
      last_name: 'Name',
      studied: 'F',
      started: '2015'
    }
    assert_equal 302, last_response.status
    updated = DB[:members].where(id: m.id).first
    assert_equal 'New', updated[:first_name]
  end
end
