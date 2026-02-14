require_relative '../test_helper'

class PartyTest < Minitest::Test
  def test_description
    p = create_party(name: "Vårfest")
    assert_equal "Vårfest, #{p.date}", p.description
  end

  def test_is_attending_true
    m = create_member
    p = create_party
    create_attendance(member: m, party: p)
    assert p.reload.attending?(m.id)
  end

  def test_is_attending_false
    m = create_member
    p = create_party
    refute p.reload.attending?(m.id)
  end

  def test_purchases_highchart_returns_six_categories
    p = create_party
    chart = p.purchases_highchart
    assert_equal 6, chart.length
    expected_names = %w(Öl Snaps Cider Bastuöl Sångbok Läsk)
    assert_equal expected_names, chart.map { |c| c[:name] }
  end

  def test_purchases_highchart_with_data
    m = create_member
    p = create_party
    create_attendance(member: m, party: p)
    article = create_article(name: "Öl")
    create_purchase(member: m, party: p, article: article, quantity: 3)

    chart = p.reload.purchases_highchart
    ol_data = chart.find { |c| c[:name] == "Öl" }
    assert_includes ol_data[:data], 3
  end
end
