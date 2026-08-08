module Dojo
  class BehaviorsController < BaseController
    before_action :set_behavior, only: %i[ edit update destroy restore ]

    def index
      @positive = behaviors_scope.active.positive.ordered
      @needs_work = behaviors_scope.active.needs_work.ordered
      @archived = behaviors_scope.archived.ordered
    end

    def new
      @behavior = behaviors_scope.new(category: params[:category].presence_in(Dojo::Behavior::CATEGORIES) || "positive",
                                      points: 1)
    end

    def edit
    end

    def create
      @behavior = behaviors_scope.new(behavior_params)

      if @behavior.save
        redirect_to dojo_behaviors_path, notice: "“#{@behavior.name}” added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @behavior.update(behavior_params)
        redirect_to dojo_behaviors_path, notice: "“#{@behavior.name}” updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @behavior.archive!
      redirect_to dojo_behaviors_path, notice: "“#{@behavior.name}” archived. Past awards are untouched."
    end

    def restore
      @behavior.restore!
      redirect_to dojo_behaviors_path, notice: "“#{@behavior.name}” is back in the picker."
    end

    # Drag-to-reorder posts the full ordered list of ids.
    def reorder
      ids = Array(params[:behavior_ids]).map(&:to_i)
      behaviors = behaviors_scope.where(id: ids).index_by(&:id)

      Dojo::Behavior.transaction do
        ids.each_with_index do |id, index|
          behaviors[id]&.update_column(:position, index + 1)
        end
      end

      head :no_content
    end

    private
      def set_behavior
        @behavior = behaviors_scope.find(params[:id])
      end

      def behavior_params
        params.require(:behavior).permit(:name, :points, :category, :icon, :color)
      end
  end
end
