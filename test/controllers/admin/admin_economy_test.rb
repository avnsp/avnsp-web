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

  def test_party_economy_defaults_attendance_fee_quantity_to_one
    admin = create_admin
    login_as(admin)
    party = create_party(price: 120)
    member = create_member
    anm = create_article(name: 'Anm')
    create_attendance(member: member, party: party)

    get "/cheferiet/economy/#{party.id}"

    assert_equal 200, last_response.status
    assert_includes last_response.body, %Q(name="purchases[]quantity" value="1")
    assert_nil DB[:purchases].where(member_id: member.id, party_id: party.id, article_id: anm.id).first
  end

  def test_party_transactions_charge_attendance_fee_once_via_purchase
    admin = create_admin
    login_as(admin)
    party = create_party(price: 120)
    member = create_member
    anm = create_article(name: 'Anm')
    create_attendance(member: member, party: party)
    DB[:parties_articles].insert(article_id: anm.id, party_id: party.id, price: 120.0)

    post "/cheferiet/economy/#{party.id}/transactions", {
      purchases: [
        { member_id: member.id.to_s, article_id: anm.id.to_s, quantity: '1' }
      ]
    }

    assert_equal 302, last_response.status
    transactions = DB[:transactions].where(member_id: member.id, party_id: party.id).all
    assert_equal 1, transactions.length
    assert_equal '1 Anm', transactions.first[:text]
    assert_equal(-120.0, transactions.first[:sum])
  end

  def test_party_economy_page_shows_financial_overview_and_totals
    admin = create_admin
    login_as(admin)
    party = create_party(price: 120)
    member = create_member
    anm = create_article(name: 'Anm')
    beer = create_article(name: 'Öl')
    create_attendance(member: member, party: party)
    DB[:parties_articles].insert(article_id: beer.id, party_id: party.id, price: 30.0)
    DB[:purchases].insert(member_id: member.id, article_id: beer.id, party_id: party.id, quantity: 2)

    get "/cheferiet/economy/#{party.id}"

    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Total försäljning'
    assert_includes last_response.body, 'Aktiva artiklar'
    assert_includes last_response.body, 'Att betala'
    assert_includes last_response.body, 'Totalt sålt'
    assert_includes last_response.body, '180 kr'
    assert_includes last_response.body, '/js/party-economy.js'
  end
end
