require_relative '../test_helper'

class HomeControllerTest < ControllerTest
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
end
