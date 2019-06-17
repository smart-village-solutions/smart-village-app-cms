class ApplicationController < ActionController::Base

  def verify_current_user
    return redirect_to log_in_path if session["current_user"].blank?
    @current_user = User.new(email: session["current_user"]["email"], token: session["current_user"]["token"])
  end

end
