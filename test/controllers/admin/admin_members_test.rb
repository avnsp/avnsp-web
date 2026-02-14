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
