class User
  attr_accessor :name, :email, :data_provider, :applications,
                :authentication_token, :roles, :permission, :minio

  def initialize(user_data)
    @email = user_data[:email]
    @password = user_data[:password]
    @authentication_token = user_data[:authentication_token]
    @data_provider = user_data[:data_provider]
    @roles = user_data[:roles]
    @applications = user_data[:applications]
    @permission = user_data[:permission]
    @minio = user_data[:minio]
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
    auth_server = SmartVillageApi.auth_server_url
    uri = Addressable::URI.parse("#{auth_server}/users/sign_in.json")
    result = ApiRequestService.new(uri.to_s, nil, nil, user_credentials).post_request
    if result.code == "200" && result.body.present?
      data = JSON.parse(result.body)
      @authentication_token = data["user"]["authentication_token"]
      @applications = data["applications"]
      @data_provider = data["data_provider"]
      @roles = data["roles"]
      @permission = data["user"]["role"]
      @minio = data["minio"]
      data
    else
      result.body
    end
  end

  def user_credentials
    { user: { email: @email, password: @password } }
  end
end
