class SessionsController < ApplicationController
  def new

  end

  def create
    user = User.find_by_username_or_email(params[:session][:username_or_email])
    if user && user.authenticate(params[:session][:password])
      sign_in user
      redirect_back_or root_url
    else
      flash.now[:error] = 'Invalid email/password combination'
      render 'new'
    end
  end

  def destroy
    sign_out
    redirect_to root_url
  end
end
