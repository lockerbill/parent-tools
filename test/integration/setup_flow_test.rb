require "test_helper"

class SetupFlowTest < ActionDispatch::IntegrationTest
  setup do
    Dojo::PointEvent.delete_all
    Dojo::Redemption.delete_all
    Family.destroy_all
  end

  test "every page redirects to the wizard until a family exists" do
    get root_path
    assert_redirected_to setup_path

    get dojo_behaviors_path
    assert_redirected_to setup_path

    get new_session_path
    assert_redirected_to setup_path
  end

  test "the wizard creates the family, the owner and the starter content" do
    assert_difference [ -> { Family.count }, -> { User.count } ], 1 do
      post setup_path, params: {
        family: { name: "The New Family" },
        user: { name: "Pat", email_address: "pat@example.com",
                password: "supersecret123", password_confirmation: "supersecret123" }
      }
    end

    family = Family.current
    assert_equal "The New Family", family.name
    assert family.owner.owner?
    assert family.behaviors.positive.any?
    assert family.behaviors.needs_work.any?
    assert family.rewards.any?

    assert_redirected_to dojo_children_path
    follow_redirect!
    assert_response :success
  end

  test "a bad password leaves nothing behind" do
    assert_no_difference [ -> { Family.count }, -> { User.count } ] do
      post setup_path, params: {
        family: { name: "The New Family" },
        user: { name: "Pat", email_address: "pat@example.com",
                password: "short", password_confirmation: "short" }
      }
    end

    assert_response :unprocessable_entity
  end

  test "the wizard cannot be replayed once a family exists" do
    post setup_path, params: {
      family: { name: "First" },
      user: { name: "Pat", email_address: "pat@example.com",
              password: "supersecret123", password_confirmation: "supersecret123" }
    }

    assert_no_difference -> { Family.count } do
      post setup_path, params: {
        family: { name: "Second" },
        user: { name: "Imposter", email_address: "nope@example.com",
                password: "supersecret123", password_confirmation: "supersecret123" }
      }
    end
  end
end
