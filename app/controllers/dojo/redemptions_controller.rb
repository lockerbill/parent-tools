module Dojo
  class RedemptionsController < BaseController
    def index
      @pending = redemptions_scope.pending.includes(:child, :reward).recent
      @decided = redemptions_scope.where.not(status: "requested").includes(:child, :reward, :user).recent.limit(50)
    end

    # A parent tapping a reward for a child: approved and deducted in one step.
    def create
      child = children_scope.active.find(params[:child_id])
      reward = rewards_scope.active.find(params[:reward_id])

      redemption = Dojo::Redemption.redeem!(child: child, reward: reward, user: current_user)
      redirect_back fallback_location: dojo_child_path(child),
                    notice: "#{child.name} redeemed “#{reward.name}” for #{redemption.cost} points."
    rescue ActiveRecord::RecordInvalid => e
      redirect_back fallback_location: dojo_rewards_path, alert: e.record.errors.full_messages.to_sentence
    end

    # Approve / decline / mark-as-given / refund for a kid's request.
    def update
      redemption = redemptions_scope.find(params[:id])
      notice = alert = nil

      case params[:commit_action]
      when "approve"
        if redemption.approve!(current_user)
          notice = "Approved “#{redemption.reward.name}” for #{redemption.child.name}."
        elsif redemption.reload.decided?
          alert = "That request has already been decided."
        else
          alert = "#{redemption.child.name} does not have enough points for that yet."
        end
      when "deny"
        notice, alert = decide(redemption.deny!(current_user), "Request declined.", "That request has already been decided.")
      when "fulfill"
        notice, alert = decide(redemption.fulfill!(current_user), "Marked as given.", "Approve it first.")
      when "cancel"
        notice, alert = decide(redemption.cancel!, "Redemption cancelled and points refunded.", "Nothing to refund.")
      else
        alert = "Unknown action."
      end

      redirect_back fallback_location: dojo_redemptions_path, notice: notice, alert: alert
    end

    private
      def decide(result, success, failure)
        result ? [ success, nil ] : [ nil, failure ]
      end
  end
end
