require_relative '../test_helper'

class AttendanceTest < Minitest::Test
  def test_nick_returns_member_nick
    m = create_member(nick: "Sigansen")
    p = create_party
    a = create_attendance(member: m, party: p)
    assert_equal "Sigansen", a.nick
  end

  def test_nick_falls_back_to_first_name
    m = create_member(first_name: "Erik", nick: nil)
    p = create_party
    a = create_attendance(member: m, party: p)
    assert_equal "Erik", a.nick
  end

  def test_member_name
    m = create_member(first_name: "Erik", last_name: "Svensson", nick: nil)
    p = create_party
    a = create_attendance(member: m, party: p)
    assert_equal "Erik Svensson", a.member_name
  end

  def test_member_studied_started
    m = create_member(studied: "F", started: 2015)
    p = create_party
    a = create_attendance(member: m, party: p)
    assert_equal "F-2015", a.member_studied_started
  end

  def test_member_previus_attendanceise_counts_same_type
    m = create_member
    p1 = create_party(name: "Fest 1", date: Date.today - 30, attendance_deadline: Date.today - 32, type: "fest")
    p2 = create_party(name: "Fest 2", date: Date.today - 10, attendance_deadline: Date.today - 12, type: "fest")
    p3 = create_party(name: "Fest 3", date: Date.today + 10, attendance_deadline: Date.today + 8, type: "fest")
    create_attendance(member: m, party: p1)
    create_attendance(member: m, party: p2)
    a3 = create_attendance(member: m, party: p3)
    assert_equal 2, a3.member_previus_attendanceise
  end

  def test_member_previus_attendanceise_separates_lunch_from_fest
    m = create_member
    p_fest = create_party(name: "Fest", date: Date.today - 10, attendance_deadline: Date.today - 12, type: "fest")
    p_lunch = create_party(name: "Lunch", date: Date.today + 10, attendance_deadline: Date.today + 8, type: "lunch")
    create_attendance(member: m, party: p_fest)
    a_lunch = create_attendance(member: m, party: p_lunch)
    assert_equal 0, a_lunch.member_previus_attendanceise
  end

  def test_add_right_foot_creates_record
    m = create_member
    p = create_party
    a = create_attendance(member: m, party: p)
    a.add_right_foot({ 'name' => 'Anna', 'vegitarian' => 'true', 'non_alcoholic' => 'false', 'allergies' => 'Nötter' })
    rf = RightFoot.where(attendance_id: a.id).first
    assert rf
    assert_equal 'Anna', rf.name
    assert_equal true, rf.vegitarian
    assert_equal false, rf.non_alcoholic
    assert_equal 'Nötter', rf.allergies
  end

  def test_add_right_foot_replaces_existing
    m = create_member
    p = create_party
    a = create_attendance(member: m, party: p)
    a.add_right_foot({ 'name' => 'Anna', 'vegitarian' => 'false', 'non_alcoholic' => 'false', 'allergies' => '' })
    a.add_right_foot({ 'name' => 'Bertil', 'vegitarian' => 'true', 'non_alcoholic' => 'true', 'allergies' => 'Gluten' })
    feet = RightFoot.where(attendance_id: a.id).all
    assert_equal 1, feet.length
    assert_equal 'Bertil', feet.first.name
  end

  def test_add_right_foot_ignores_nil
    m = create_member
    p = create_party
    a = create_attendance(member: m, party: p)
    a.add_right_foot(nil)
    assert_equal 0, RightFoot.where(attendance_id: a.id).count
  end

  def test_add_right_foot_ignores_empty_name
    m = create_member
    p = create_party
    a = create_attendance(member: m, party: p)
    a.add_right_foot({ 'name' => '', 'vegitarian' => 'false', 'non_alcoholic' => 'false', 'allergies' => '' })
    assert_equal 0, RightFoot.where(attendance_id: a.id).count
  end
end
