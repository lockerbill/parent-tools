module Dojo
  class DashboardController < BaseController
    def show
      @children = children_scope.active.ordered.with_attached_avatar
      @recent_events = point_events_scope.includes(:child, :behavior, :user).recent.limit(15)
      @pending_redemptions = redemptions_scope.pending.includes(:child, :reward).recent
    end
  end
end
