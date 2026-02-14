require_relative '../../test_helper'

class AdminReminderTest < ControllerTest
  def test_non_admin_gets_403
    m = create_member(admin: false)
    login_as(m)
    get '/cheferiet/reminder/'
    assert_equal 403, last_response.status
  end

  def test_index_shows_negative_balances
    admin = create_admin
    login_as(admin)
    m = create_member(first_name: "Skuld")
    create_transaction(member: m, sum: -100)
    get '/cheferiet/reminder/'
    assert_equal 200, last_response.status
    assert_includes last_response.body, 'Skuld'
  end

  def test_post_sends_reminders
    admin = create_admin
    login_as(admin)
    m = create_member(first_name: "Skuld", email: "skuld@academian.se")
    create_transaction(member: m, sum: -100)
    post '/cheferiet/reminder/'
    assert_equal 302, last_response.status
    # Verify a message was published
    assert TH.published.any? { |msg| msg[:routing_key] == 'member.reminder' }
  end

  def test_reminder_uses_member_email_not_hardcoded
    admin = create_admin
    login_as(admin)
    m = create_member(first_name: "Test", email: "real@academian.se")
    create_transaction(member: m, sum: -50)
    post '/cheferiet/reminder/'
    reminder_msg = TH.published.find { |msg| msg[:routing_key] == 'member.reminder' }
    assert reminder_msg
    assert_equal 'real@academian.se', reminder_msg[:data][:email]
  end
end
