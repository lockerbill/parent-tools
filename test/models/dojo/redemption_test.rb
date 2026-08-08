require "test_helper"

module Dojo
  class RedemptionTest < ActiveSupport::TestCase
    setup do
      @child = children(:ada)          # balance 10
      @reward = dojo_rewards(:screen_time) # cost 5
      @expensive = dojo_rewards(:movie)    # cost 30
      @user = users(:owner)
    end

    test "a parent redeeming deducts immediately" do
      redemption = Redemption.redeem!(child: @child, reward: @reward, user: @user)

      assert redemption.approved?
      assert_equal 5, redemption.cost
      assert_equal 5, @child.reload.points_balance
    end

    test "a redemption the child cannot afford is refused" do
      assert_raises(ActiveRecord::RecordInvalid) do
        Redemption.redeem!(child: @child, reward: @expensive, user: @user)
      end

      assert_equal 10, @child.reload.points_balance
    end

    test "a kid request does not move points until approval" do
      redemption = Redemption.request!(child: @child, reward: @reward)

      assert redemption.requested?
      assert_equal 10, @child.reload.points_balance

      assert redemption.approve!(@user)
      assert redemption.reload.approved?
      assert_equal @user, redemption.user
      assert_equal 5, @child.reload.points_balance
    end

    test "approving fails when the balance has fallen too low" do
      redemption = Redemption.request!(child: @child, reward: @reward)
      @child.update!(points_balance: 1)

      refute redemption.approve!(@user)
      assert redemption.reload.requested?
      assert_equal 1, @child.reload.points_balance
    end

    test "denying leaves the balance alone" do
      redemption = dojo_redemptions(:ada_requested)

      assert redemption.deny!(@user)
      assert redemption.reload.denied?
      assert_equal 10, @child.reload.points_balance
    end

    test "fulfilling is bookkeeping only" do
      redemption = Redemption.redeem!(child: @child, reward: @reward, user: @user)
      balance = @child.reload.points_balance

      assert redemption.fulfill!(@user)
      assert redemption.reload.fulfilled?
      assert_equal balance, @child.reload.points_balance
    end

    test "cancelling refunds the points" do
      redemption = Redemption.redeem!(child: @child, reward: @reward, user: @user)
      assert_equal 5, @child.reload.points_balance

      assert redemption.cancel!
      assert redemption.reload.denied?
      assert_equal 10, @child.reload.points_balance
    end

    # Two parents tapping at the same moment must not both win. Each of these
    # holds a second, stale handle on the same row.
    test "a second handle cannot refund the same redemption twice" do
      redemption = Redemption.redeem!(child: @child, reward: @reward, user: @user)
      stale = Redemption.find(redemption.id)

      assert redemption.cancel!
      refute stale.cancel!

      assert_equal 10, @child.reload.points_balance
      assert_equal @child.points_balance, @child.balance_from_ledger
    end

    test "a stale handle cannot decline an already approved redemption" do
      redemption = Redemption.request!(child: @child, reward: @reward)
      stale = Redemption.find(redemption.id)

      assert stale.approve!(@user)
      refute redemption.deny!(@user)

      assert_equal 5, @child.reload.points_balance
      assert_equal @child.points_balance, @child.balance_from_ledger
    end

    test "a stale handle cannot mark a refunded redemption as given" do
      redemption = Redemption.redeem!(child: @child, reward: @reward, user: @user)
      stale = Redemption.find(redemption.id)

      assert redemption.cancel!
      refute stale.fulfill!(@user)

      assert_equal 10, @child.reload.points_balance
      assert_equal @child.points_balance, @child.balance_from_ledger
    end

    test "the state machine refuses out-of-order transitions" do
      redemption = dojo_redemptions(:ada_requested)

      refute redemption.fulfill!(@user), "cannot fulfil something not yet approved"
      assert redemption.approve!(@user)
      refute redemption.approve!(@user), "cannot approve twice"
    end
  end
end
