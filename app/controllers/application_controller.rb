class ApplicationController < ActionController::Base

  def verify_current_user
    return redirect_to log_in_path if session["current_user"].blank?
    user_data = {
      email: session["current_user"]["email"],
      data_provider: session["current_user"]["data_provider"],
      applications: session["current_user"]["applications"]
    }

    @current_user = User.new(user_data)
  end

  def init_graphql_client
    @smart_village = SmartVillageApi.new(user: @current_user).client
  end

end
