require_relative '../../test_helper'

class AdminBalanceTest < ControllerTest
  def test_non_admin_gets_403
    m = create_member(admin: false)
    login_as(m)
    get '/cheferiet/balance/'
    assert_equal 403, last_response.status
  end

  def test_index_shows_balances
    admin = create_admin
    login_as(admin)
    m = create_member(first_name: "Saldo", last_name: "Testare")
    create_transaction(member: m, sum: 500)
    get '/cheferiet/balance/'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Saldo Testare'
  end

  def test_member_balance_page
    admin = create_admin
    login_as(admin)
    m = create_member
    create_transaction(member: m, sum: 200, text: "Insättning")
    get "/cheferiet/balance/#{m.id}"
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Insättning'
  end
end
