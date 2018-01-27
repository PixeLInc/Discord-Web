module Discord
  # Represents a token object
  class Token
    attr_accessor :token

    attr_accessor :refresh_token

    attr_accessor :expires_at

    def initialize(token, refresh, expires)
      @token = token
      @refresh_token = refresh
      @expires_at = expires
    end

    def expired?
      expires_at = Time.at((DateTime.now + @expires_at).to_time.to_i)

      expires_at > Time.now
    end
  end
end
