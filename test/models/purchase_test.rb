require_relative '../test_helper'

class PurchaseTest < Minitest::Test
  def test_name_delegates_to_article
    m = create_member
    p = create_party
    a = create_article(name: "Snaps")
    purchase = create_purchase(member: m, party: p, article: a, quantity: 2)
    assert_equal "Snaps", purchase.name
  end
end
