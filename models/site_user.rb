module Discord
  # Represents a cached user
  class SiteUser
    attr_reader :name

    attr_reader :discriminator

    attr_reader :email

    attr_reader :uid

    attr_reader :created_at

    attr_reader :updated_at

    def initialize(name, discrim, email, uid, cat, uat)
      @name = name
      @discriminator = discrim
      @email = email
      @uid = uid
      @created_at = cat
      @updated_at = uat 
    end
  end
end
