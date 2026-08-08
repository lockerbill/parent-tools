module Kids
  # The kid view is a shared-tablet experience: no email, no password, just a
  # child card and a PIN. It can never create or change point events.
  class BaseController < ApplicationController
    allow_unauthenticated_access
    before_action :require_kid_view_enabled
    layout "kids"

    helper_method :current_child

    private
      # Never redirect to root_path here: root is the parent dashboard, which
      # bounces non-parents back to the kid view, and the two would loop.
      def require_kid_view_enabled
        return if current_family&.kid_view_enabled?

        if current_user&.parent_access?
          redirect_to dojo_dashboard_path, alert: "The kid view is turned off."
        else
          redirect_to new_session_path, alert: "The kid view is turned off."
        end
      end

      def current_child
        @current_child ||= current_family.children.active.find_by(id: session[:kid_child_id])
      end

      def require_child!
        redirect_to kids_root_path unless current_child
      end
  end
end
