require "test_helper"

module Dojo
  class PointEventTest < ActiveSupport::TestCase
    setup do
      @child = children(:ada)     # balance 10
      @bo = children(:bo)         # balance 0
      @user = users(:owner)
      @helping = dojo_behaviors(:helping)   # +2
      @teasing = dojo_behaviors(:teasing)   # -2
    end

    test "awarding a behaviour moves the balance and records the ledger row" do
      assert_difference -> { @child.reload.points_balance }, 2 do
        event = PointEvent.award!(child: @child, user: @user, behavior: @helping)
        assert_equal 2, event.points
        assert_equal 2, event.requested_points
        assert_equal "Helping at home", event.label
        assert_equal @user, event.user
      end
    end

    test "a deduction is capped so the balance never goes below zero" do
      @child.update!(points_balance: 1)

      event = PointEvent.award!(child: @child, user: @user, behavior: @teasing)

      assert_equal(-1, event.points, "only the point they actually had is taken")
      assert_equal(-2, event.requested_points, "the full request is still recorded")
      assert event.clamped?
      assert_equal 0, @child.reload.points_balance
    end

    test "a deduction against an empty balance records a zero-point event" do
      event = PointEvent.award!(child: @bo, user: @user, behavior: @teasing)

      assert_equal 0, event.points
      assert_equal(-2, event.requested_points)
      refute event.positive?, "it is still a needs-work event, whatever survived clamping"
      assert_equal 0, @bo.reload.points_balance
    end

    test "an award is never inflated by the clamp" do
      family.update_settings(allow_negative_balance: true)
      @child.update!(points_balance: -10)

      event = PointEvent.award!(child: @child.reload, user: @user, behavior: @helping)

      assert_equal 2, event.points
      assert_equal(-8, @child.reload.points_balance)
    end

    # Turning the setting off while a child is already below zero must not turn
    # the next deduction into a windfall.
    test "a deduction against an already negative balance never becomes an award" do
      family.update_settings(allow_negative_balance: true)
      PointEvent.award!(child: @child, user: @user, points: -30, label: "Broken window")
      assert_equal(-20, @child.reload.points_balance)

      family.update_settings(allow_negative_balance: false)
      event = PointEvent.award!(child: @child.reload, user: @user, behavior: @teasing)

      assert_equal 0, event.points
      assert_equal(-2, event.requested_points)
      assert_equal(-20, @child.reload.points_balance)
      assert_equal @child.points_balance, @child.balance_from_ledger
    end

    test "families that allow negative balances get the full deduction" do
      family.update_settings(allow_negative_balance: true)
      @child.update!(points_balance: 1)

      event = PointEvent.award!(child: @child.reload, user: @user, behavior: @teasing)

      assert_equal(-2, event.points)
      refute event.clamped?
      assert_equal(-1, @child.reload.points_balance)
    end

    test "manual adjustments need a label and non-zero points" do
      event = PointEvent.award!(child: @child, user: @user, points: 5, label: "Tidied the lounge")

      assert_equal 5, event.points
      assert_equal "Tidied the lounge", event.label
      assert_nil event.behavior

      assert_raises(ArgumentError) { PointEvent.award!(child: @child, user: @user, points: 0) }
    end

    test "awarding many children in one tap is all-or-nothing" do
      children = [ children(:ada), children(:bo) ]

      events = PointEvent.award_many!(children: children, user: @user, behavior: @helping)

      assert_equal 2, events.size
      assert_equal 12, children(:ada).reload.points_balance
      assert_equal 2, children(:bo).reload.points_balance
    end

    test "undo reverses the balance without deleting history" do
      event = PointEvent.award!(child: @child, user: @user, behavior: @helping)
      assert_equal 12, @child.reload.points_balance

      assert_difference -> { PointEvent.count }, 0 do
        assert event.revert!
      end

      assert event.reload.reverted?
      assert_equal 10, @child.reload.points_balance
    end

    test "undo is idempotent" do
      event = PointEvent.award!(child: @child, user: @user, behavior: @helping)
      event.revert!

      refute event.revert!
      assert_equal 10, @child.reload.points_balance
    end

    test "undo is refused outside the window" do
      old = PointEvent.award!(child: @child, user: @user, behavior: @helping, occurred_at: 2.days.ago)

      refute old.undoable?
      refute old.revert!
      assert_equal 12, @child.reload.points_balance
    end

    test "undo is refused once the points have been spent" do
      event = PointEvent.award!(child: @bo, user: @user, points: 5, label: "Big help")
      Dojo::Redemption.redeem!(child: @bo, reward: dojo_rewards(:screen_time), user: @user)
      assert_equal 0, @bo.reload.points_balance

      refute event.revert!, "undoing would put Bo below zero"
      refute event.reload.reverted?
      assert_equal 0, @bo.reload.points_balance
    end

    test "reverted events no longer count towards the balance" do
      event = PointEvent.award!(child: @child, user: @user, behavior: @helping)
      event.revert!

      assert_equal @child.reload.points_balance, @child.balance_from_ledger
    end
  end
end
