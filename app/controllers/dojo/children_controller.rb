module Dojo
  class ChildrenController < BaseController
    before_action :set_child, only: %i[ show edit update destroy restore ]

    def index
      @children = children_scope.ordered.with_attached_avatar
    end

    def show
      @recent_events = @child.point_events.includes(:behavior, :user).recent.limit(20)
      @rewards = rewards_scope.active.ordered
      @redemptions = @child.redemptions.includes(:reward, :user).recent.limit(10)
    end

    def new
      @child = children_scope.new
    end

    def edit
    end

    def create
      @child = children_scope.new(child_params)

      if @child.save
        redirect_to dojo_children_path, notice: "#{@child.name} added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @child.update(child_params)
        redirect_to dojo_children_path, notice: "#{@child.name} updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    # Archiving keeps every ledger row intact; only the dashboard gets quieter.
    def destroy
      @child.archive!
      redirect_to dojo_children_path, notice: "#{@child.name} archived. Their history is kept."
    end

    def restore
      @child.restore!
      redirect_to dojo_children_path, notice: "#{@child.name} is back on the dashboard."
    end

    private
      def set_child
        @child = children_scope.find(params[:id])
      end

      def child_params
        permitted = params.require(:child).permit(:name, :birthdate, :color, :emoji, :avatar, :pin, :pin_confirmation, :remove_avatar)
        @child&.avatar&.purge_later if permitted.delete(:remove_avatar) == "1" && @child&.avatar&.attached?
        permitted.delete(:pin) if permitted[:pin].blank?
        permitted.delete(:pin_confirmation) if permitted[:pin_confirmation].blank?
        permitted
      end
  end
end
