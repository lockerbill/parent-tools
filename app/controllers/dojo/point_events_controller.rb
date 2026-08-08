module Dojo
  class PointEventsController < BaseController
    PAGE_SIZE = 50

    before_action :set_selected_children, only: %i[ new create ]

    # The behaviour picker sheet. Opened from a child card (or from a multi-select).
    def new
      @behaviors = behaviors_scope.active.ordered
    end

    def create
      @behavior = behaviors_scope.active.find_by(id: params[:behavior_id])
      points = params[:points].presence&.to_i
      points = nil if points&.zero? # a behaviour's own value wins; 0 is never an award

      if @selected_children.empty?
        return redirect_to dojo_dashboard_path, alert: "Pick a child first."
      end

      if @behavior.nil? && (points.nil? || points.zero?)
        return redirect_to dojo_dashboard_path, alert: "Pick a behaviour first."
      end

      @events = Dojo::PointEvent.award_many!(
        children: @selected_children,
        user: current_user,
        behavior: @behavior,
        points: points,
        label: params[:label].presence,
        note: params[:note].presence
      )

      load_dashboard_state

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to dojo_dashboard_path, notice: award_notice }
      end
    end

    def index
      @events = point_events_scope.includes(:child, :behavior, :user).recent
      @events = @events.where(child_id: params[:child_id]) if params[:child_id].present?
      @events = @events.where(dojo_point_events: { id: ...params[:before].to_i }) if params[:before].present?
      @events = @events.limit(PAGE_SIZE + 1).to_a
      @more = @events.size > PAGE_SIZE
      @events = @events.first(PAGE_SIZE)
      @children = children_scope.ordered
    end

    # Undo. When one tap awarded several children at once, undo takes back the
    # whole group, and either all of it goes back or none of it does.
    def revert
      @event = point_events_scope.find(params[:id])
      ids = (Array(params[:revert_group]).map(&:to_i) + [ @event.id ]).uniq
      @events = point_events_scope.active.where(id: ids).includes(:child, :behavior, :user).to_a

      reverted = revert_group(@events)
      @event.reload
      load_dashboard_state

      respond_to do |format|
        if reverted
          format.turbo_stream
          format.html { redirect_back fallback_location: dojo_dashboard_path, notice: "Undone." }
        else
          format.turbo_stream { redirect_back fallback_location: dojo_dashboard_path, alert: undo_refused_message }
          format.html { redirect_back fallback_location: dojo_dashboard_path, alert: undo_refused_message }
        end
      end
    end

    private
      def revert_group(events)
        return false if events.empty?

        Dojo::PointEvent.transaction do
          raise ActiveRecord::Rollback unless events.all?(&:revert!)
          return true
        end

        false
      end

      def undo_refused_message
        "Those points can no longer be undone — they may already be spent, or the award is more than a day old. " \
        "Award an adjustment instead."
      end

      def load_dashboard_state
        @children = children_scope.active.ordered.with_attached_avatar
        @recent_events = point_events_scope.includes(:child, :behavior, :user).recent.limit(15)
      end

      def set_selected_children
        ids = Array(params[:child_ids]).reject(&:blank?)
        ids = [ params[:child_id] ] if ids.empty? && params[:child_id].present?
        @selected_children = children_scope.active.where(id: ids).ordered.to_a
      end

      def award_notice
        names = @selected_children.map(&:name).to_sentence
        "#{@events.first.label} #{@events.first.signed_points} for #{names}."
      end
  end
end
