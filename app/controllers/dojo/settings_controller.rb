module Dojo
  class SettingsController < BaseController
    before_action :require_owner!, only: :update

    def show
      @family = current_family
      @children = children_scope.ordered
    end

    def update
      @family = current_family
      submitted = params.fetch(:family, ActionController::Parameters.new)

      @family.name = submitted[:name] if submitted[:name].present?
      @family.settings = @family.settings.merge(submitted_settings(submitted))

      if @family.save
        redirect_to dojo_settings_path, notice: "Settings saved."
      else
        @children = children_scope.ordered
        render :show, status: :unprocessable_entity
      end
    end

    private
      # Only touch the switches the form actually sent. A partial update (or a
      # rename from an API client) must not silently turn the kid view off.
      def submitted_settings(submitted)
        changes = {}

        %w[ allow_negative_balance kid_view_enabled kid_requests_enabled ].each do |key|
          changes[key] = submitted[key] == "1" if submitted.key?(key)
        end

        if submitted[:week_start_day].present? && Family::WEEK_START_DAYS.include?(submitted[:week_start_day])
          changes["week_start_day"] = submitted[:week_start_day]
        end

        changes
      end
  end
end
