class UsersController < ApplicationController
  def new
    @user = User.new
    render 'new', layout: 'simple'
  end

  def create
    @user = User.new(user_params)
    if @user.save
      sign_in @user
      flash[:success] = "Welcome to the Sample App!"
      redirect_to root_url
    else
      render 'new'
    end
  end

  private

  def user_params
    params.require(:user).permit :username, :email, :password,
      :password_confirmation
  end
end
