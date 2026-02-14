require_relative '../../test_helper'

class AdminEconomyTest < ControllerTest
  def test_non_admin_gets_403
    m = create_member(admin: false)
    login_as(m)
    get '/cheferiet/economy/'
    assert_equal 403, last_response.status
  end

  def test_index_lists_parties
    admin = create_admin
    login_as(admin)
    create_party(name: "Ekonomifest")
    get '/cheferiet/economy/'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Ekonomifest'
  end

  def test_deposit_form
    admin = create_admin
    login_as(admin)
    get '/cheferiet/economy/deposit'
    assert_equal 200, last_response.status
  end

  def test_deposit_creates_transaction
    admin = create_admin
    login_as(admin)
    m = create_member
    post '/cheferiet/economy/deposit', {
      member_id: m.id,
      sum: '100',
      date: Date.today.to_s
    }
    assert_equal 302, last_response.status
    t = DB[:transactions].where(member_id: m.id, text: 'Insättning').first
    assert t
    assert_equal 100.0, t[:sum]
  end

  def test_deposit_validation_empty_sum
    admin = create_admin
    login_as(admin)
    m = create_member
    post '/cheferiet/economy/deposit', {
      member_id: m.id,
      sum: '',
      date: Date.today.to_s
    }
    assert_equal 401, last_response.status
  end

  def test_party_economy_page
    admin = create_admin
    login_as(admin)
    p = create_party
    m = create_member
    create_attendance(member: m, party: p)
    get "/cheferiet/economy/#{p.id}"
    assert_equal 200, last_response.status
  end
end
