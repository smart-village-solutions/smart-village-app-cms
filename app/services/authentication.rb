class Authentication
  attr_accessor :client_id, :client_secret, :settings

  def initialize(client_id:, client_secret:)
    @client_id = client_id
    @client_secret = client_secret
    @settings = {}
  end

  def load_access_tokens
    auth_server = Rails.application.credentials.auth_server[:url]
    uri = Addressable::URI.parse("#{auth_server}/oauth/token")
    uri.query_values = {
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: Rails.application.credentials.auth_server[:callback_url],
      grant_type: "client_credentials"
    }

    result = ApiRequestService.new(uri.to_s, nil, nil, uri.query_values).post_request

    if result.code == "200" && result.body.present?
      data = JSON.parse(result.body)
      save_tokens(data)
    else
      result.body
    end
  end

  def access_token
    load_access_tokens
    settings["access_token"]
  end

  private

    def save_tokens(token_hash)
      settings["access_token"] = token_hash.fetch("access_token", "")
      settings["expires_in"] = token_hash.fetch("expires_in", "")
      settings["created_at"] = token_hash.fetch("created_at", "")
    end
end
