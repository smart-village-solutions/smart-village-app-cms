class SmartVillageApi
  attr_accessor :user

  def initialize(user:)
    @user = user
  end


  def client
    token = @user.get_access_token

    Graphlient::Client.new("#{SmartVillageApi.auth_server_url}/graphql",
      headers: {
        'Authorization' => "Bearer #{token}"
      }
    )
  end

  def self.auth_server_url
    return Rails.application.credentials.auth_server[:url] if Rails.env.production?

    "http://localhost:3000"
  end
end
