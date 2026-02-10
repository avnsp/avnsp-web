require_relative '../test_helper'

class MemberTest < Minitest::Test
  def test_full_name_without_nick
    m = create_member(first_name: "Erik", last_name: "Svensson", nick: nil)
    assert_equal 'Erik Svensson', m.full_name
  end

  def test_full_name_with_nick
    m = create_member(first_name: "Erik", last_name: "Svensson", nick: "Sigansen")
    assert_equal 'Erik "Sigansen" Svensson', m.full_name
  end

  def test_parties_returns_sorted_by_date
    m = create_member
    p1 = create_party(name: "Fest 1", date: Date.today + 10, attendance_deadline: Date.today + 8)
    p2 = create_party(name: "Fest 2", date: Date.today + 5, attendance_deadline: Date.today + 3)
    create_attendance(member: m, party: p1)
    create_attendance(member: m, party: p2)
    parties = m.reload.parties
    assert_equal [p2.id, p1.id], parties.map(&:id)
  end

  def test_parties_filters_by_date
    m = create_member
    past = create_party(name: "Past", date: Date.today - 10, attendance_deadline: Date.today - 12)
    future = create_party(name: "Future", date: Date.today + 10, attendance_deadline: Date.today + 8)
    create_attendance(member: m, party: past)
    create_attendance(member: m, party: future)
    parties = m.reload.parties(Date.today)
    assert_equal 1, parties.length
    assert_equal past.id, parties.first.id
  end

  def test_attendance_found
    m = create_member
    p = create_party
    a = create_attendance(member: m, party: p)
    result = m.reload.attendance(p.id)
    assert_equal a.id, result.id
  end

  def test_attendance_not_found_returns_new
    m = create_member
    result = m.attendance(999)
    assert_instance_of Attendance, result
    assert_nil result.id
  end

  def test_balance_with_transactions
    m = create_member
    create_transaction(member: m, sum: -100.0)
    create_transaction(member: m, sum: 50.0)
    assert_equal(-50.0, m.balance)
  end

  def test_balance_zero_when_no_transactions
    m = create_member
    assert_equal 0, m.balance
  end

  def test_password_set_and_verify
    m = create_member
    m.password = "secret123"
    m.save
    m.reload
    assert_equal true, (m.password == "secret123")
    refute m.password == "wrong"
  end

  def test_profile_picture_cdn
    m = create_member(profile_picture: "photos/profile.jpg")
    assert_equal "https://www.academian.se/photos/profile.jpg", m.profile_picture_cdn
  end

  def test_thumb_cdn
    m = create_member(profile_picture: "photos/profile.jpg")
    assert_equal "https://www.academian.se/photos/profile.jpg.thumb", m.thumb_cdn
  end
end
