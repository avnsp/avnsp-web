require_relative '../test_helper'

class EventWorkerTest < Minitest::Test
  def setup
    super
    @worker = EventWorker.new
    @worker.extend(TestAmqp)
    @worker.start
  end

  def test_photo_uploaded_inserts_event
    @worker.simulate("photo.uploaded", { path: "photos/test.jpg" })
    evt = DB[:events].order(:id).last
    assert evt
    assert_equal "photo", evt[:name]
  end

  def test_photo_uploaded_publishes_created
    @worker.simulate("photo.uploaded", { path: "photos/test.jpg" })
    assert @worker.published.any? { |p| p[:topic] == "event.photo.created" }
  end

  def test_member_created_inserts_event
    @worker.simulate("member.created", { id: 1, name: "Test" })
    evt = DB[:events].order(:id).last
    assert evt
    assert_equal "member", evt[:name]
  end

  def test_member_created_publishes_created
    @worker.simulate("member.created", { id: 1, name: "Test" })
    assert @worker.published.any? { |p| p[:topic] == "event.member.created" }
  end

  def test_party_created_inserts_event
    @worker.simulate("party.created", { id: 1, name: "Fest" })
    evt = DB[:events].order(:id).last
    assert evt
    assert_equal "party", evt[:name]
  end
end
