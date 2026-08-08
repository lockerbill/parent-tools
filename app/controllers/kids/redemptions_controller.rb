module Kids
  class RedemptionsController < BaseController
    before_action :require_child!

    def create
      unless current_family.kid_requests_enabled?
        return redirect_to kids_dashboard_path, alert: "Ask a grown-up to swap your points."
      end

      reward = current_family.rewards.active.find(params[:reward_id])

      if current_child.redemptions.pending.exists?(reward_id: reward.id)
        redirect_to kids_dashboard_path, notice: "You already asked for “#{reward.name}”."
      elsif !reward.affordable_for?(current_child)
        redirect_to kids_dashboard_path, alert: "You need #{reward.cost - current_child.points_balance} more points for that."
      else
        Dojo::Redemption.request!(child: current_child, reward: reward)
        redirect_to kids_dashboard_path, notice: "Asked for “#{reward.name}”. A grown-up will say yes or no."
      end
    end
  end
end
