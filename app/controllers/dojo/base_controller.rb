module Dojo
  class BaseController < ApplicationController
    before_action :require_parent!

    private
      def children_scope
        current_family.children
      end

      def behaviors_scope
        current_family.behaviors
      end

      def rewards_scope
        current_family.rewards
      end

      def point_events_scope
        Dojo::PointEvent.where(child_id: children_scope.select(:id))
      end

      def redemptions_scope
        Dojo::Redemption.where(child_id: children_scope.select(:id))
      end

      def pending_redemptions_count
        @pending_redemptions_count ||= redemptions_scope.pending.count
      end
      helper_method :pending_redemptions_count
  end
end
