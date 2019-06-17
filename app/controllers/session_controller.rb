class SessionController < ApplicationController

  def create
    if params[:email].present? && params[:password].present?
      @current_user = User.new(email: params[:email], password: params[:password])
      if @current_user.valid?
        session["current_user"] = {}
        session["current_user"]["email"] = @current_user.email
        session["current_user"]["token"] = @current_user.token
        redirect_to root_path()
      else
        redirect_to log_in_path()
      end
    end
  end

  def destroy
    session.destroy
    flash[:notice] = "You have been successfully logged off"
    redirect_to root_path()
  end
end
