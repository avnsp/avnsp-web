require_relative '../test_helper'

class MemberControllerTest < ControllerTest
  def test_get_members_index
    m = create_member
    login_as(m)
    get '/member/'
    assert_equal 200, last_response.status
  end

  def test_get_member_show
    m = create_member
    login_as(m)
    get "/member/#{m.id}"
    assert_equal 200, last_response.status
  end

  def test_get_profile_edit
    m = create_member
    login_as(m)
    get '/member/profile-edit'
    assert_equal 200, last_response.status
  end

  def test_post_profile_edit
    m = create_member(first_name: "Erik")
    login_as(m)
    post '/member/profile-edit', {
      first_name: "Karl",
      last_name: m.last_name,
      email: m.email,
      studied: m.studied,
      started: m.started.to_s,
      phone: "",
      street: "",
      city: "",
      zip: ""
    }, 'HTTP_REFERER' => '/member/profile-edit'
    assert_equal 302, last_response.status
    m.reload
    assert_equal "Karl", m.first_name
  end

  def test_put_nick
    m = create_member
    login_as(m)
    put "/member/#{m.id}/nick", { nick: "Sigansen" }
    assert_equal 200, last_response.status
    m.reload
    assert_equal "Sigansen", m.nick
  end

  def test_put_nick_empty_clears
    m = create_member(nick: "OldNick")
    login_as(m)
    put "/member/#{m.id}/nick", { nick: "" }
    assert_equal 200, last_response.status
    m.reload
    assert_nil m.nick
  end

  def test_get_transactions
    m = create_member
    login_as(m)
    create_transaction(member: m, sum: -50.0, text: "Fest")
    get "/member/#{m.id}/transactions"
    assert_equal 200, last_response.status
  end
end
