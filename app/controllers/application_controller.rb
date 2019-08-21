class ApplicationController < ActionController::Base

  def verify_current_user
    return redirect_to log_in_path if session["current_user"].blank?
    user_data = {
      email: session["current_user"]["email"],
      authentication_token: session["current_user"]["authentication_token"],
      applications: session["current_user"]["applications"],
      roles: session["current_user"]["roles"]
    }

    @current_user = User.new(user_data)
  end

  def init_graphql_client
    @smart_village = SmartVillageApi.new(user: @current_user).client
  end

end
