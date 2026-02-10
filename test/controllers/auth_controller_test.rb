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
    token = Digest::SHA1.hexdigest("reset@academian.se:#{ts}:#{ENV['SESSION_SECRET']}")
    get '/change-password', { email: "reset@academian.se", ts: ts, token: token }
    assert_equal 200, last_response.status
  end

  def test_post_change_password_success
    m = create_member(email: "reset@academian.se")
    ts = Time.now.to_i.to_s
    token = Digest::SHA1.hexdigest("reset@academian.se:#{ts}:#{ENV['SESSION_SECRET']}")
    post '/change-password', {
      email: "reset@academian.se",
      ts: ts,
      token: token,
      password: "newpass123"
    }
    assert_equal 302, last_response.status
    m.reload
    assert m.password == "newpass123"
  end

  def test_unauthenticated_redirects_to_login
    get '/'
    assert_equal 302, last_response.status
    assert_includes last_response.location, '/login'
  end
end
