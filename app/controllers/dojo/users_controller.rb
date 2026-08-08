module Dojo
  class UsersController < BaseController
    before_action :require_owner!, except: :index

    def index
      @users = current_family.users.order(:role, :name)
    end

    def new
      @user = current_family.users.new(role: "parent")
    end

    def create
      @user = current_family.users.new(user_params)
      @user.role = "parent" unless User.roles.key?(@user.role)

      if @user.save
        redirect_to dojo_users_path, notice: "#{@user.name} can now sign in."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      user = current_family.users.find(params[:id])

      if user.deletable_by?(current_user)
        user.destroy
        redirect_to dojo_users_path, notice: "#{user.name} removed."
      else
        redirect_to dojo_users_path, alert: "That account cannot be removed."
      end
    end

    private
      def user_params
        params.require(:user).permit(:name, :email_address, :password, :password_confirmation, :role)
      end
  end
end
