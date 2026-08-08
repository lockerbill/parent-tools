class ApplicationController < ActionController::Base
  include Authentication

  # No `allow_browser` guard on purpose: the shared family tablet in the kitchen is
  # often several years old, and locking it out of the kid view helps nobody.

  prepend_before_action :require_setup
  before_action :set_current_family

  helper_method :current_family

  private
    # Nothing works until the first-boot wizard has created a family.
    def require_setup
      redirect_to setup_path unless Family.installed?
    end

    def set_current_family
      Current.family = current_user&.family || Family.current
    end

    def current_family
      Current.family
    end

    def require_parent!
      return if current_user&.parent_access?

      if current_family&.kid_view_enabled?
        redirect_to kids_root_path, alert: "That area is for parents."
      else
        redirect_to new_session_path, alert: "That area is for parents."
      end
    end

    def require_owner!
      return if current_user&.owner?

      redirect_to dojo_dashboard_path, alert: "Only the family owner can do that."
    end
end
