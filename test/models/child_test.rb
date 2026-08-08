require "test_helper"

class ChildTest < ActiveSupport::TestCase
  setup do
    @child = children(:ada)
    @user = users(:owner)
  end

  test "balance can be rebuilt from the ledger at any time" do
    Dojo::PointEvent.award!(child: @child, user: @user, behavior: dojo_behaviors(:homework))
    Dojo::Redemption.redeem!(child: @child, reward: dojo_rewards(:screen_time), user: @user)

    expected = @child.reload.points_balance
    @child.update_columns(points_balance: 999)

    @child.recalculate_balance!

    assert_equal expected, @child.reload.points_balance
  end

  # This is the invariant the whole ledger design rests on.
  test "the cached balance equals the ledger after clamping, undo and redemption" do
    bo = children(:bo)

    Dojo::PointEvent.award!(child: bo, user: @user, points: 5, label: "Tidied up")
    Dojo::PointEvent.award!(child: bo, user: @user, points: -10, label: "Shouting")  # clamped to -5
    assert_equal 0, bo.reload.points_balance

    Dojo::PointEvent.award!(child: bo, user: @user, points: 8, label: "Great week")
    event = Dojo::PointEvent.award!(child: bo, user: @user, points: 2, label: "Extra")
    Dojo::Redemption.redeem!(child: bo, reward: dojo_rewards(:screen_time), user: @user)
    event.revert!

    assert_equal bo.reload.points_balance, bo.balance_from_ledger
    refute_equal 0, bo.points_balance, "the sequence should leave a real balance behind"
  end

  test "PINs must be four to six digits" do
    @child.pin = "12"
    refute @child.valid?

    @child.pin = "123456"
    assert @child.valid?

    @child.pin = "abcd"
    refute @child.valid?
  end

  test "PIN confirmation must match when given" do
    @child.pin = "1234"
    @child.pin_confirmation = "4321"
    refute @child.valid?

    @child.pin_confirmation = "1234"
    assert @child.valid?
  end

  test "a set PIN authenticates" do
    assert @child.authenticate_pin("1234")
    refute @child.authenticate_pin("9999")
  end

  test "archiving keeps the child and their history" do
    events = @child.point_events.count
    @child.archive!

    assert @child.archived?
    refute_includes Child.active, @child
    assert_equal events, @child.point_events.count
  end

  test "age is nil without a birthdate" do
    assert_nil @child.age

    @child.birthdate = 8.years.ago.to_date
    assert_equal 8, @child.age
  end
end
