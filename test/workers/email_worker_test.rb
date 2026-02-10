require_relative '../test_helper'

class EmailWorkerTest < Minitest::Test
  def setup
    super
    @worker = EmailWorker.new
    @worker.extend(TestAmqp)
    @emails_sent = []
    # Stub send_email to capture calls instead of sending
    @worker.define_singleton_method(:send_email) do |to, sub, ct, body|
      @emails_sent ||= []
      @emails_sent << { to: to, subject: sub, content_type: ct, body: body }
    end
    @worker.instance_variable_set(:@emails_sent, @emails_sent)
    @worker.start
  end

  def emails_sent
    @worker.instance_variable_get(:@emails_sent)
  end

  def test_member_reset_password_handler
    @worker.simulate("member.reset-password", {
      email: "test@academian.se",
      hostname: "localhost:9292",
      token: "abc123",
      ts: Time.now.to_i.to_s
    })
    assert_equal 1, emails_sent.length
    assert_equal "test@academian.se", emails_sent.first[:to]
    assert_includes emails_sent.first[:subject], "lösenord"
  end

  def test_member_reminder_handler
    @worker.simulate("member.reminder", {
      email: "test@academian.se",
      name: "Erik",
      balance: -200
    })
    assert_equal 1, emails_sent.length
    assert_includes emails_sent.first[:body], "Erik"
    assert_includes emails_sent.first[:body], "-200"
  end

  def test_member_login_handler
    @worker.simulate("member.login", {
      email: "test@academian.se",
      token: "abc",
      ts: "123",
      hostname: "localhost:9292"
    })
    assert_equal 1, emails_sent.length
    assert_equal "test@academian.se", emails_sent.first[:to]
  end

  def test_send_invitations_handler
    @worker.simulate("send-invitations", {
      email: "test@academian.se",
      nick: "Sigansen",
      party_date: "2024-05-01",
      party_name: "Vårfest",
      party_last_att_date: "2024-04-24",
      party_id: 1,
      balance: -100,
      balance_after: -250,
      street: "Studentgatan 1",
      zip: "22100",
      city: "Lund"
    })
    assert_equal 1, emails_sent.length
    assert_includes emails_sent.first[:subject], "Vårfest"
  end
end
