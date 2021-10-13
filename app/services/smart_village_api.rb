# frozen_string_literal: true

class SmartVillageApi
  attr_accessor :user

  def initialize(user:)
    @user = user
  end

  def client
    token = @user.get_access_token

    Graphlient::Client.new(
      "#{SmartVillageApi.auth_server_url}/graphql",
      headers: {
        "Authorization" => "Bearer #{token}"
      }
    )
  end

  def self.auth_server_url
    Rails.application.credentials.auth_server[:url]
  end

  def self.encounter_server_url
    Rails.application.credentials.encounter_server[:url]
  end
end
