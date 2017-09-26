module Discord
  # Represents a cached user
  class SiteUser
    attr_reader :name

    attr_reader :discriminator

    attr_reader :email

    attr_reader :uid

    def initialize(name, discrim, email, uid)
      @name = name
      @discriminator = discrim
      @email = email
      @uid = uid
    end
  end
end
