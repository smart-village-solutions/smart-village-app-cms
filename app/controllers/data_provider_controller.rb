class DataProviderController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client

  def edit
    @data_provider = OpenStruct.new(@current_user.data_provider)
  end

  def update
    flash[:error] = "Feature noch nicht implementiert"
    redirect_to "/data_provider"
  end

end
