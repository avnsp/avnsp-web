require_relative '../test_helper'

class AuthControllerTest < ControllerTest
  def test_get_login
    get '/login'
    assert_equal 200, last_response.status
  end

  def test_get_login_redirects_when_logged_in
    m = create_member
    login_as(m)
    get '/login'
    assert_equal 302, last_response.status
    assert_equal '/', URI.parse(last_response.location).path
  end

  def test_post_login_success
    m = create_member(email: "test@academian.se")
    m.password = "secret123"
    m.save
    post '/login', { email: "test@academian.se", password: "secret123" },
         'HTTP_REFERER' => '/login'
    assert_equal 302, last_response.status
  end

  def test_post_login_unknown_email
    post '/login', { email: "nobody@academian.se", password: "x" },
         'HTTP_REFERER' => '/login'
    assert_equal 302, last_response.status
  end

  def test_post_login_no_password_triggers_reset
    create_member(email: "nopass@academian.se")
    post '/login', { email: "nopass@academian.se", password: "" },
         'HTTP_REFERER' => '/login'
    assert_equal 302, last_response.status
    assert TH.published.any? { |p| p[:routing_key] == "member.reset-password" }
  end

  def test_post_logout
    m = create_member
    login_as(m)
    post '/logout'
    assert_equal 302, last_response.status
  end

  def test_get_forgotten
    get '/forgotten'
    assert_equal 200, last_response.status
  end

  def test_post_forgotten
    create_member(email: "forgot@academian.se")
    post '/forgotten', { email: "forgot@academian.se" },
         'HTTP_REFERER' => '/forgotten'
    assert_equal 302, last_response.status
  end

  def test_get_change_password_with_valid_token
    create_member(email: "reset@academian.se")
    ts = Time.now.to_i.to_s
    token = OpenSSL::HMAC.hexdigest("SHA256", ENV['SESSION_SECRET'], "reset@academian.se:#{ts}")
    get '/change-password', { email: "reset@academian.se", ts: ts, token: token }
    assert_equal 200, last_response.status
  end

  def test_post_change_password_success
    m = create_member(email: "reset@academian.se")
    ts = Time.now.to_i.to_s
    token = OpenSSL::HMAC.hexdigest("SHA256", ENV['SESSION_SECRET'], "reset@academian.se:#{ts}")
    post '/change-password', {
      email: "reset@academian.se",
      ts: ts,
      token: token,
      password: "newpass123",
      password2: "newpass123"
    }
    assert_equal 302, last_response.status
    m.reload
    assert m.password == "newpass123"
  end

  def test_post_forgotten_keeps_current_password
    m = member_with_password("forgot@academian.se")
    post '/forgotten', { email: "forgot@academian.se" }, 'HTTP_REFERER' => '/forgotten'
    assert TH.published.any? { |p| p[:routing_key] == "member.reset-password" }
    assert Member[m.id].password == "oldpass"
  end

  def test_emailed_link_opens_form_and_changes_password
    m = member_with_password("reset@academian.se")
    post '/forgotten', { email: "reset@academian.se" }, 'HTTP_REFERER' => '/forgotten'
    data = TH.published.find { |p| p[:routing_key] == "member.reset-password" }[:data]
    link = { email: data[:email], ts: data[:ts], token: data[:token] }
    get '/change-password', link
    assert_includes last_response.body, "name='password'"
    post '/change-password', link.merge(password: "newpass", password2: "newpass")
    assert Member[m.id].password == "newpass"
  end

  def test_link_works_only_once
    m = member_with_password("reset@academian.se")
    link = reset_link(m)
    post '/change-password', link.merge(password: "first", password2: "first")
    assert Member[m.id].password == "first"

    post '/change-password', link.merge(password: "second", password2: "second")
    assert Member[m.id].password == "first"
    assert_equal '/forgotten', URI.parse(last_response.location).path
  end

  def test_expired_link_shows_no_form_and_is_refused
    m = member_with_password("reset@academian.se")
    link = reset_link(m, ts: Time.now.to_i - 3601)
    get '/change-password', link
    assert_equal 200, last_response.status
    refute_includes last_response.body, "name='password'"
    assert_includes last_response.body, "Begär en ny länk"

    post '/change-password', link.merge(password: "newpass", password2: "newpass")
    assert Member[m.id].password == "oldpass"
  end

  def test_link_still_works_shortly_before_expiry
    m = member_with_password("reset@academian.se")
    link = reset_link(m, ts: Time.now.to_i - 3500)
    post '/change-password', link.merge(password: "newpass", password2: "newpass")
    assert Member[m.id].password == "newpass"
  end

  def test_wrong_token_shows_no_form
    member_with_password("reset@academian.se")
    get '/change-password', { email: "reset@academian.se", ts: Time.now.to_i, token: "fel" }
    refute_includes last_response.body, "name='password'"
  end

  def test_change_password_without_params_shows_no_form
    get '/change-password'
    assert_equal 200, last_response.status
    refute_includes last_response.body, "name='password'"
  end

  def test_mismatched_passwords_change_nothing_and_return_to_form
    m = member_with_password("reset+tag@academian.se")
    link = reset_link(m)
    post '/change-password', link.merge(password: "newpass", password2: "typo")
    assert Member[m.id].password == "oldpass"
    assert_equal '/change-password', URI.parse(last_response.location).path

    get last_response.location
    assert_includes last_response.body, "name='password'"
  end

  def test_blank_password_changes_nothing
    m = member_with_password("reset@academian.se")
    post '/change-password', reset_link(m).merge(password: "", password2: "")
    assert Member[m.id].password == "oldpass"
  end

  def test_unauthenticated_redirects_to_login
    get '/'
    assert_equal 302, last_response.status
    assert_includes last_response.location, '/login'
  end

  private

  def member_with_password(email)
    m = create_member(email:)
    m.password = "oldpass"
    m.save
    m
  end

  def reset_link(member, ts: Time.now.to_i)
    member = Member[member.id]
    message = "#{member.email}:#{ts}:#{member.password_hash}"
    token = OpenSSL::HMAC.hexdigest("SHA256", ENV['SESSION_SECRET'], message)
    { email: member.email, ts: ts, token: token }
  end
end
