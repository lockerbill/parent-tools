require "test_helper"

class KidViewTest < ActionDispatch::IntegrationTest
  setup do
    @ada = children(:ada)   # PIN 1234
    @bo = children(:bo)     # no PIN
  end

  test "the picker shows the children without any sign in" do
    get kids_root_path

    assert_response :success
    assert_match @ada.name, response.body
  end

  test "a correct PIN opens the dashboard" do
    unlock_kid @ada, pin: "1234"
    assert_redirected_to kids_dashboard_path

    follow_redirect!
    assert_response :success
    assert_match @ada.points_balance.to_s, response.body
  end

  test "a wrong PIN does not" do
    unlock_kid @ada, pin: "0000"
    assert_redirected_to kids_root_path(child_id: @ada.id)

    get kids_dashboard_path
    assert_redirected_to kids_root_path
  end

  test "a child without a PIN opens straight away" do
    unlock_kid @bo
    assert_redirected_to kids_dashboard_path
  end

  test "kids can request a reward but never award points" do
    unlock_kid @bo
    @bo.update!(points_balance: 50)

    assert_difference -> { Dojo::Redemption.pending.count }, 1 do
      post kids_redemptions_path, params: { reward_id: dojo_rewards(:screen_time).id }
    end

    assert_equal 50, @bo.reload.points_balance, "requesting must not move points"

    # There is no route into the parent side from the kid session.
    get dojo_dashboard_path
    assert_redirected_to new_session_path

    assert_no_difference -> { Dojo::PointEvent.count } do
      post dojo_point_events_path, params: { child_ids: [ @bo.id ], behavior_id: dojo_behaviors(:helping).id }
    end
  end

  test "requesting a reward they cannot afford is refused" do
    unlock_kid @bo

    assert_no_difference -> { Dojo::Redemption.count } do
      post kids_redemptions_path, params: { reward_id: dojo_rewards(:movie).id }
    end
  end

  test "the same reward cannot be requested twice" do
    unlock_kid @ada, pin: "1234"

    assert_no_difference -> { Dojo::Redemption.count } do
      post kids_redemptions_path, params: { reward_id: dojo_rewards(:screen_time).id }
    end
  end

  test "turning the kid view off closes it" do
    family.update_settings(kid_view_enabled: false)

    get kids_root_path
    assert_redirected_to new_session_path
  end

  test "leaving clears the session" do
    unlock_kid @bo
    delete kids_session_path

    get kids_dashboard_path
    assert_redirected_to kids_root_path
  end
end
