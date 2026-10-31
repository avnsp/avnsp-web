require_relative '../../test_helper'

class AdminMeritsTest < ControllerTest
  def setup
    super
    @member = create_member
  end

  def merits
    DB[:merits].where(member_id: @member.id)
  end

  def add_merit(attrs = {})
    DB[:merits].insert({ member_id: @member.id, appointment: "Kassör", start: "2020-01-01", end: "2020-12-31" }.merge(attrs))
  end

  def test_non_admin_cannot_add_change_or_remove
    id = add_merit
    login_as(create_member(admin: false))

    post "/cheferiet/members/#{@member.id}/merits", { appointment: "Ordförande" }
    assert_equal 403, last_response.status
    post "/cheferiet/members/#{@member.id}/merits/#{id}", { appointment: "Ordförande" }
    assert_equal 403, last_response.status
    post "/cheferiet/members/#{@member.id}/merits/#{id}/delete"
    assert_equal 403, last_response.status

    assert_equal ["Kassör"], merits.select_map(:appointment)
  end

  def test_logged_out_cannot_add
    post "/cheferiet/members/#{@member.id}/merits", { appointment: "Ordförande" }
    assert_includes last_response.location, '/login'
    assert_equal 0, merits.count
  end

  def test_member_page_shows_merit_form_and_existing_merits
    add_merit
    login_as(create_admin)
    get "/cheferiet/members/#{@member.id}"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "value='Kassör'"
    assert_includes last_response.body, "value='2020-01-01'"
    assert_includes last_response.body, "Lägg till merit"
  end

  def test_new_member_page_has_no_merit_section
    login_as(create_admin)
    get "/cheferiet/members/new"
    assert_equal 200, last_response.status
    refute_includes last_response.body, "Lägg till merit"
  end

  def test_add_merit
    login_as(create_admin)
    post "/cheferiet/members/#{@member.id}/merits", { appointment: " Kassör ", start: "2021-01-01", end: "2021-12-31" }
    assert_equal 302, last_response.status
    assert_includes last_response.location, "/cheferiet/members/#{@member.id}"
    merit = merits.first
    assert_equal "Kassör", merit[:appointment]
    assert_equal Date.new(2021, 1, 1), merit[:start]
    assert_equal Date.new(2021, 12, 31), merit[:end]
  end

  def test_add_merit_without_dates
    login_as(create_admin)
    post "/cheferiet/members/#{@member.id}/merits", { appointment: "Hedersmedlem", start: "", end: "" }
    assert_equal 302, last_response.status
    assert_nil merits.first[:start]
    assert_nil merits.first[:end]
  end

  def test_add_merit_needs_title_and_keeps_what_was_typed
    login_as(create_admin)
    post "/cheferiet/members/#{@member.id}/merits", { appointment: "  ", start: "2021-01-01" }
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Ange en titel."
    assert_includes last_response.body, "value='2021-01-01'"
    assert_equal 0, merits.count
  end

  def test_add_merit_refuses_end_before_start
    login_as(create_admin)
    post "/cheferiet/members/#{@member.id}/merits", { appointment: "Kassör", start: "2021-01-01", end: "2020-01-01" }
    assert_equal 422, last_response.status
    assert_includes last_response.body, "Slutdatum kan inte vara före startdatum."
    assert_equal 0, merits.count
  end

  def test_add_merit_refuses_invalid_date
    login_as(create_admin)
    post "/cheferiet/members/#{@member.id}/merits", { appointment: "Kassör", start: "inte-ett-datum" }
    assert_equal 422, last_response.status
    assert_equal 0, merits.count
  end

  def test_add_merit_to_missing_member_returns_404
    login_as(create_admin)
    post "/cheferiet/members/999999/merits", { appointment: "Kassör" }
    assert_equal 404, last_response.status
  end

  def test_update_merit
    id = add_merit
    login_as(create_admin)
    post "/cheferiet/members/#{@member.id}/merits/#{id}", { appointment: "Ordförande", start: "2022-01-01", end: "" }
    assert_equal 302, last_response.status
    merit = merits.first
    assert_equal "Ordförande", merit[:appointment]
    assert_equal Date.new(2022, 1, 1), merit[:start]
    assert_nil merit[:end]
  end

  def test_update_with_error_changes_nothing
    id = add_merit
    login_as(create_admin)
    post "/cheferiet/members/#{@member.id}/merits/#{id}", { appointment: "" }
    assert_equal 422, last_response.status
    assert_equal "Kassör", merits.first[:appointment]
  end

  def test_delete_merit
    id = add_merit
    keep = add_merit(appointment: "Ordförande")
    login_as(create_admin)
    post "/cheferiet/members/#{@member.id}/merits/#{id}/delete"
    assert_equal 302, last_response.status
    assert_equal [keep], merits.select_map(:id)
  end

  def test_cannot_touch_merit_through_another_member
    id = add_merit
    other = create_member
    login_as(create_admin)
    post "/cheferiet/members/#{other.id}/merits/#{id}", { appointment: "Ordförande" }
    assert_equal 404, last_response.status
    post "/cheferiet/members/#{other.id}/merits/#{id}/delete"
    assert_equal 404, last_response.status
    assert_equal ["Kassör"], merits.select_map(:appointment)
  end

  def test_profile_and_matrikel_show_merits
    add_merit
    add_merit(appointment: "Ordförande", start: "2022-01-01", end: nil)
    login_as(create_member)

    get "/member/#{@member.id}"
    assert_equal 200, last_response.status
    assert_operator last_response.body.index("Ordförande"), :<, last_response.body.index("Kassör")

    get "/member/"
    assert_includes last_response.body, "Ordförande, Kassör"
  end

  def test_profile_shows_title_first_then_dates
    add_merit
    add_merit(appointment: "Ordförande", start: "2022-01-01", end: nil)
    add_merit(appointment: "Hedersmedlem", start: nil, end: nil)
    login_as(create_member)
    get "/member/#{@member.id}"
    assert_match %r{<dt>Kassör</dt>\s*<dd>2020-01-01 – 2020-12-31</dd>}, last_response.body
    assert_match %r{<dt>Ordförande</dt>\s*<dd>Från 2022-01-01</dd>}, last_response.body
    assert_match %r{<dt>Hedersmedlem</dt>\s*</dl>}, last_response.body
  end

  def test_profile_has_no_edit_controls_for_merits
    add_merit
    login_as(@member)
    get "/member/#{@member.id}"
    refute_includes last_response.body, "/merits"
  end
end
