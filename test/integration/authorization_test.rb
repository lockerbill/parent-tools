require "test_helper"

class AuthorizationTest < ActionDispatch::IntegrationTest
  test "the parent side needs a session" do
    [ dojo_dashboard_path, dojo_children_path, dojo_behaviors_path,
      dojo_rewards_path, dojo_settings_path, dojo_point_events_path ].each do |path|
      get path
      assert_redirected_to new_session_path, "#{path} should require a sign in"
    end
  end

  test "a kid_viewer account cannot reach the parent side" do
    viewer = family.users.create!(name: "Kid", email_address: "kid@example.com",
                                  password: "supersecret123", role: "kid_viewer")
    sign_in_as viewer

    get dojo_dashboard_path
    assert_redirected_to kids_root_path

    assert_no_difference -> { Dojo::PointEvent.count } do
      post dojo_point_events_path, params: { child_ids: [ children(:ada).id ], behavior_id: dojo_behaviors(:helping).id }
    end
  end

  test "only the owner manages parent accounts" do
    sign_in_as users(:parent)

    get dojo_users_path
    assert_response :success

    get new_dojo_user_path
    assert_redirected_to dojo_dashboard_path
  end

  test "new parent accounts cannot elevate their submitted role" do
    sign_in_as users(:owner)

    assert_difference -> { family.users.count }, 1 do
      post dojo_users_path, params: {
        user: {
          name: "Second Parent",
          email_address: "second-parent@example.com",
          password: "supersecret123",
          password_confirmation: "supersecret123",
          role: "owner"
        }
      }
    end

    assert_equal "parent", family.users.find_by!(email_address: "second-parent@example.com").role
  end

  test "only the owner changes family settings" do
    sign_in_as users(:parent)

    patch dojo_settings_path, params: { family: { name: "Renamed" } }

    assert_redirected_to dojo_dashboard_path
    assert_equal "The Lockers", family.reload.name
  end

  test "sign in is rate limited" do
    11.times do
      post session_path, params: { email_address: "bill@example.com", password: "wrong" }
    end

    assert_equal "Too many attempts. Try again in a few minutes.", flash[:alert]
  end
end
