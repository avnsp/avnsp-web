require_relative '../../test_helper'

class AdminDashboardTest < ControllerTest
  def test_non_admin_gets_403
    m = create_member(admin: false)
    login_as(m)
    get '/cheferiet/'
    assert_equal 403, last_response.status
  end

  def test_admin_gets_200
    m = create_admin
    login_as(m)
    get '/cheferiet/'
    assert_equal 200, last_response.status
  end

  def test_members_index_has_new_member_link
    admin = create_admin
    login_as(admin)
    get '/cheferiet/members/'
    assert_includes last_response.body, 'Ny medlem'
  end

  def test_parties_index_has_new_party_link
    admin = create_admin
    login_as(admin)
    get '/cheferiet/parties/'
    assert_includes last_response.body, 'Ny fest'
  end
end
