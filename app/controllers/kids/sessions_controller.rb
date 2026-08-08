module Kids
  class SessionsController < BaseController
    rate_limit to: 10, within: 3.minutes, only: :create,
               with: -> { redirect_to kids_root_path, alert: "Too many tries. Wait a few minutes." }

    def new
      @children = current_family.children.active.ordered.with_attached_avatar.to_a
      @child = @children.detect { |child| child.id == params[:child_id].to_i } if params[:child_id].present?
    end

    def create
      child = current_family.children.active.find_by(id: params[:child_id])

      if child.nil?
        redirect_to kids_root_path, alert: "Pick your name to start."
      elsif !child.pin? || child.authenticate_pin(params[:pin].to_s)
        session[:kid_child_id] = child.id
        redirect_to kids_dashboard_path
      else
        redirect_to kids_root_path(child_id: child.id), alert: "That PIN did not match. Try again."
      end
    end

    def destroy
      session.delete(:kid_child_id)
      redirect_to kids_root_path, notice: "See you next time."
    end
  end
end
