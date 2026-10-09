require_relative '../test_helper'

class HomeControllerTest < ControllerTest
  def test_user_menu_works_without_focus_and_has_phone_links
    m = create_member
    login_as(m)
    get '/'
    body = last_response.body
    assert_match %r{<details class=['"]dropdown['"]>}, body
    links = body[%r{<ul class=['"]nav-user-links['"]>.*?</ul>}m]
    assert links, "phone menu links missing"
    assert_match %r{href=['"]/member/#{m.id}['"]>Profil<}, links
    assert_match %r{href=['"]/member/profile-edit['"]>Ändra<}, links
    assert_includes links, "Logga ut"
  end

  def test_get_home_authenticated
    m = create_member
    login_as(m)
    # Create a future party so the query returns results
    create_party(name: "Upcoming", date: Date.today + 7, attendance_deadline: Date.today + 5)
    get '/'
    assert_equal 200, last_response.status
  end

  def test_get_home_shows_upcoming_parties
    m = create_member
    login_as(m)
    create_party(name: "Framtid", date: Date.today + 14, attendance_deadline: Date.today + 12)
    get '/'
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Framtid"
  end

  def test_get_home_shows_signup_on_attendance_deadline
    m = create_member
    login_as(m)
    party = create_party(name: "Deadline idag", date: Date.today + 7, attendance_deadline: Date.today)
    get '/'
    assert_equal 200, last_response.status
    assert_includes last_response.body, "Deadline idag"
    assert_includes last_response.body, "/party/#{party.id}/attend"
  end
end
