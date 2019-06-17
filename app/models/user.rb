class User
  attr_accessor :name, :email, :token

  def initialize(email:, token: nil, password: nil)
    @email = email
    @name = "Marco Metz"
    @token = token
  end

  def gravatar_url
    hashed_email = Digest::MD5.hexdigest(email)
    "https://www.gravatar.com/avatar/#{hashed_email}"
  end

  def valid?
    # TODO: Implementierung fehlt
    true
  end

end
