require "test_helper"

class AwardingPointsTest < ActionDispatch::IntegrationTest
  setup do
    @ada = children(:ada)
    @bo = children(:bo)
    @helping = dojo_behaviors(:helping)
    sign_in_as users(:owner)
  end

  test "the dashboard lists the active children" do
    get dojo_dashboard_path

    assert_response :success
    assert_select "#children"
    assert_match @ada.name, response.body
    refute_match children(:archie).name, response.body
  end

  test "the picker opens for one child" do
    get new_dojo_point_event_path(child_id: @ada.id)

    assert_response :success
    assert_match @helping.name, response.body
  end

  test "awarding over turbo streams updates the balance and the feed" do
    post dojo_point_events_path,
         params: { child_ids: [ @ada.id ], behavior_id: @helping.id },
         as: :turbo_stream

    assert_response :success
    assert_equal 12, @ada.reload.points_balance
    assert_match "activity_feed", response.body
    assert_match "Undo", response.body
  end

  test "one tap can award several children" do
    post dojo_point_events_path,
         params: { child_ids: [ @ada.id, @bo.id ], behavior_id: @helping.id },
         as: :turbo_stream

    assert_equal 12, @ada.reload.points_balance
    assert_equal 2, @bo.reload.points_balance
  end

  test "undo takes back the whole group" do
    post dojo_point_events_path,
         params: { child_ids: [ @ada.id, @bo.id ], behavior_id: @helping.id },
         as: :turbo_stream

    events = Dojo::PointEvent.order(:id).last(2)

    post revert_dojo_point_event_path(events.first),
         params: { revert_group: events.map(&:id) },
         as: :turbo_stream

    assert_response :success
    assert_equal 10, @ada.reload.points_balance
    assert_equal 0, @bo.reload.points_balance
    assert events.all? { |event| event.reload.reverted? }
  end

  test "awarding with no child selected is refused" do
    assert_no_difference -> { Dojo::PointEvent.count } do
      post dojo_point_events_path, params: { child_ids: [], behavior_id: @helping.id }
    end

    assert_redirected_to dojo_dashboard_path
  end

  test "a child from another family cannot be awarded" do
    other = Family.create!(name: "Someone else")
    stranger = other.children.create!(name: "Stranger")

    assert_no_difference -> { Dojo::PointEvent.count } do
      post dojo_point_events_path, params: { child_ids: [ stranger.id ], behavior_id: @helping.id }
    end
  end

  test "signing out closes the door" do
    delete session_path

    get dojo_dashboard_path
    assert_redirected_to new_session_path
  end
end
