class SetupController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :require_setup

  def show
    redirect_to root_path, notice: "HomeDojo is already set up." and return if Family.installed?

    @family = Family.new(name: "Our family")
    @user = User.new
  end

  def create
    if Family.installed?
      redirect_to root_path, notice: "HomeDojo is already set up." and return
    end

    @family = Family.new(family_params)
    @user = User.new(user_params.merge(role: "owner"))

    if valid_setup?
      install!
      start_new_session_for @user
      redirect_to dojo_children_path, notice: "Welcome to HomeDojo. Add your children to get started."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private
    def family_params
      params.require(:family).permit(:name)
    end

    def user_params
      params.require(:user).permit(:name, :email_address, :password, :password_confirmation)
    end

    # Validate both records before writing either one, so a bad password never
    # leaves a half-installed family behind.
    def valid_setup?
      family_ok = @family.valid?
      @user.family = @family
      user_ok = @user.valid?
      family_ok && user_ok
    end

    def install!
      ActiveRecord::Base.transaction do
        @family.save!
        @user.family = @family
        @user.save!
        Dojo::Behavior.seed_defaults!(@family)
        Dojo::Reward.seed_defaults!(@family)
      end
    end
end
