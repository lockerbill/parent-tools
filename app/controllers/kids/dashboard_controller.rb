module Kids
  class DashboardController < BaseController
    before_action :require_child!

    def show
      @child = current_child
      @recent_events = @child.point_events.active.includes(:behavior).recent.limit(10)
      @rewards = current_family.rewards.active.ordered
      @redemptions = @child.redemptions.includes(:reward).recent.limit(5)
      @report = Dojo::ChildReport.new(@child, days: 7)
    end
  end
end
