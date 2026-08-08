require "test_helper"

class RewardsFlowTest < ActionDispatch::IntegrationTest
  setup do
    @ada = children(:ada)   # balance 10
    @screen_time = dojo_rewards(:screen_time)  # 5
    sign_in_as users(:owner)
  end

  test "a parent redeems straight from a child's page" do
    post dojo_redemptions_path, params: { child_id: @ada.id, reward_id: @screen_time.id }

    assert_equal 5, @ada.reload.points_balance
    assert Dojo::Redemption.order(:id).last.approved?
  end

  test "an unaffordable redemption is refused with a message" do
    post dojo_redemptions_path, params: { child_id: @ada.id, reward_id: dojo_rewards(:movie).id }

    assert_equal 10, @ada.reload.points_balance
    assert flash[:alert].present?
  end

  test "a pending request can be approved" do
    redemption = dojo_redemptions(:ada_requested)

    patch dojo_redemption_path(redemption, commit_action: "approve")

    assert redemption.reload.approved?
    assert_equal 5, @ada.reload.points_balance
  end

  test "a pending request can be declined without cost" do
    redemption = dojo_redemptions(:ada_requested)

    patch dojo_redemption_path(redemption, commit_action: "deny")

    assert redemption.reload.denied?
    assert_equal 10, @ada.reload.points_balance
  end

  test "an approved redemption can be refunded" do
    redemption = dojo_redemptions(:ada_requested)
    patch dojo_redemption_path(redemption, commit_action: "approve")

    patch dojo_redemption_path(redemption, commit_action: "cancel")

    assert_equal 10, @ada.reload.points_balance
  end

  test "behaviours can be reordered" do
    ids = family.behaviors.active.ordered.pluck(:id).reverse

    patch reorder_dojo_behaviors_path, params: { behavior_ids: ids }, as: :json

    assert_response :no_content
    assert_equal ids, family.behaviors.active.ordered.pluck(:id)
  end

  test "archiving a behaviour keeps it out of the picker" do
    behavior = dojo_behaviors(:helping)

    delete dojo_behavior_path(behavior)
    follow_redirect! # consume the "archived" flash so it cannot pollute the next body

    assert behavior.reload.archived?
    get new_dojo_point_event_path(child_id: @ada.id)
    refute_match behavior.name, response.body
  end
end
