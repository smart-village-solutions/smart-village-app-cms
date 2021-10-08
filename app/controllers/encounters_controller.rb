class EncountersController < ApplicationController
  before_action :verify_current_user

  def index
    # Display form to load Account by SupportID
  end

  def show
    support_id = params[:support_id]
    # server_url = Settings.encounter_server[:url]
    server_url = "http://localhost:2000"

    # main_server_url = SmartVillageApi.auth_server_url
    main_server_url = "http://localhost:4000"

    uri = Addressable::URI.parse("#{server_url}/v1/support/user_by_support_id.json?")
    params_to_send = {
      support_id: support_id,
      server_url: main_server_url,
      auth_token: session["current_user"]["authentication_token"]
    }
    result = ApiRequestService.new(uri.to_s, nil, nil, params_to_send).get_request

    if result.code == "200" && result.body.present?
      @data = JSON.parse(result.body)
    else
      @data = result.body
    end
  end
end
