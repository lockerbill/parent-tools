require "application_system_test_case"

# This is the product. If this test breaks, the app is broken.
class AwardingPointsTest < ApplicationSystemTestCase
  setup do
    @ada = children(:ada)
    @bo = children(:bo)
    sign_in_as users(:owner)
  end

  test "three taps: child, behaviour, done" do
    visit dojo_dashboard_path
    assert_text @ada.name

    click_on @ada.name                       # 1: open the picker for Ada
    assert_text "Helping at home"

    click_on "Helping at home"               # 2: award

    assert_text "Undo"                       # 3: the toast confirms it
    within "##{dom_id(@ada)}" do
      assert_text "12"
    end
    assert_equal 12, @ada.reload.points_balance
  end

  test "undo puts the points back" do
    visit dojo_dashboard_path
    click_on @ada.name
    click_on "Helping at home"

    assert_text "Undo"
    within("#toasts") { click_on "Undo" } # the feed row has its own Undo button

    assert_text "back to 10 points"
    assert_equal 10, @ada.reload.points_balance
  end

  test "several children at once" do
    visit dojo_dashboard_path

    check "Select #{@ada.name}"
    check "Select #{@bo.name}"
    click_on "Award points →"

    assert_text "Homework done"
    click_on "Homework done"
    assert_text "Homework done +3 · Ada and Bo"

    assert_equal 13, @ada.reload.points_balance
    assert_equal 3, @bo.reload.points_balance
  end

  test "a deduction stops at zero" do
    visit dojo_dashboard_path

    click_on @bo.name                        # Bo has 0 points
    click_on "Needs work"
    click_on "Teasing"

    assert_equal 0, @bo.reload.points_balance
  end

  private
    def sign_in_as(user, password: "supersecret123")
      visit new_session_path
      fill_in "Email address", with: user.email_address
      fill_in "Password", with: password
      click_on "Sign in"
      assert_no_text "Sign in"
    end
end
