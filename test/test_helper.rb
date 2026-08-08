ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    fixtures :all

    # `rate_limit` counts through Rails.cache, which is a real memory store in
    # test and would otherwise leak sign-in attempts between tests.
    setup { Rails.cache.clear }

    # Every fixture belongs to the one family; this keeps tests readable.
    def family
      families(:lockers)
    end
  end
end

class ActionDispatch::IntegrationTest
  # Signs in as a parent without going through the form every time.
  def sign_in_as(user, password: "supersecret123")
    post session_path, params: { email_address: user.email_address, password: password }
    user
  end

  def unlock_kid(child, pin: nil)
    post kids_session_path, params: { child_id: child.id, pin: pin }
  end
end
