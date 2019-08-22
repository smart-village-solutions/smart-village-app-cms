class DataProviderController < ApplicationController
  before_action :verify_current_user
  before_action :init_graphql_client

  def edit
    auth_server = SmartVillageApi.auth_server_url
    uri = Addressable::URI.parse("#{auth_server}/data_provider/edit.json")
    data_to_send = { auth_token: @current_user.authentication_token }
    result = ApiRequestService.new(uri.to_s, nil, nil, data_to_send).get_request
    if result.code == "200"
      @data_provider = OpenStruct.new(JSON.parse(result.body))
    else
      flash[:error] = "Achtung! Verbindungsproblem zum Server, bitte versuchen sie es später noch einmal (#{result.body})"
    end
  end

  def update
    auth_server = SmartVillageApi.auth_server_url
    uri = Addressable::URI.parse("#{auth_server}/data_provider/update.json")
    data_to_send = {
      data_provider: data_provider_params,
      auth_token: @current_user.authentication_token
    }
    result = ApiRequestService.new(uri.to_s, nil, nil, data_to_send).post_request

    if result.code == "200"
      flash[:notice] = "DataProvider wurde erfolgreich gespeichert"
    else
      flash[:error] = result.inspect
    end

    redirect_to "/data_provider"
  end

  def data_provider_params
    params.permit!.require(:data_provider)
  end
end
