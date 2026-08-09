require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include ActionView::RecordIdentifier

  driven_by :selenium, using: :headless_chrome, screen_size: [ 420, 900 ] do |options|
    if ENV["CHROME_NO_SANDBOX"] == "1"
      options.add_argument("--no-sandbox")
      options.add_argument("--disable-dev-shm-usage")
    end
  end

  # Checkboxes on the dashboard are labelled for screen readers, not visually.
  Capybara.enable_aria_label = true
end
