module Dojo
  class RewardsController < BaseController
    before_action :set_reward, only: %i[ edit update destroy restore ]

    def index
      @rewards = rewards_scope.active.ordered
      @archived = rewards_scope.archived.ordered
      @children = children_scope.active.ordered
    end

    def new
      @reward = rewards_scope.new(cost: 20)
    end

    def edit
    end

    def create
      @reward = rewards_scope.new(reward_params)

      if @reward.save
        redirect_to dojo_rewards_path, notice: "“#{@reward.name}” added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @reward.update(reward_params)
        redirect_to dojo_rewards_path, notice: "“#{@reward.name}” updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @reward.archive!
      redirect_to dojo_rewards_path, notice: "“#{@reward.name}” archived."
    end

    def restore
      @reward.restore!
      redirect_to dojo_rewards_path, notice: "“#{@reward.name}” is back in the catalogue."
    end

    private
      def set_reward
        @reward = rewards_scope.find(params[:id])
      end

      def reward_params
        params.require(:reward).permit(:name, :cost, :icon)
      end
  end
end
