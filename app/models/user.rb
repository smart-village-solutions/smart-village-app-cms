class User
  attr_accessor :name, :email, :data_provider, :applications

  def initialize(email:, password: nil, data_provider: nil, applications: nil)
    @email = email
    @password = password
    @data_provider = data_provider
    @applications = applications
  end

  def gravatar_url
    hashed_email = Digest::MD5.hexdigest(email)
    "https://www.gravatar.com/avatar/#{hashed_email}"
  end

  def valid?
    @applications.present?
  end

  def name
    return "" if @data_provider.blank?
    @data_provider.fetch("name", "")
  end

  # sign_in first to load access_token
  def get_access_token
    app = @applications.first
    client_id = app["uid"]
    client_secret = app["secret"]
    access_token = Authentication.new(client_id: client_id, client_secret: client_secret ).access_token
  end

  def sign_in
    uri = Addressable::URI.parse("#{SmartVillageApi.auth_server_url}/users/sign_in.json")
    user_credentials = { user: { email: @email, password: @password } }
    result = ApiRequestService.new(uri.to_s, nil, nil, user_credentials).post_request
    if result.code == "200" && result.body.present?
      data = JSON.parse(result.body)
      @applications = data["applications"]
      @data_provider = data["data_provider"]
      data
    else
      result.body
    end
  end
end
