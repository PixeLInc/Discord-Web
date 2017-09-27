module Discord
  # Represents a cached user
  class DiscordUser
    attr_reader :name

    attr_reader :discriminator

    attr_reader :email

    attr_reader :uid

    attr_reader :avatar

    attr_reader :bot

    attr_reader :mfa_enabled

    attr_reader :verified

    def initialize(name, discrim, email, uid, avatar, bot, mfa, verified)
      @name = name
      @discriminator = discrim
      @email = email
      @uid = uid
      @avatar = avatar
      @bot = bot
      @mfa_enabled = mfa
      @verified = verified
    end
  end
end
