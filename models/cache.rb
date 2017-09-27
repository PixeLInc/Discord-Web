module Discord
  # Provides a simple cache for my site
  module Cache
    extend self

    require_relative 'site_user'
    require_relative 'token'

    def init
      @users = {}
      @guilds = {}
      @channels = {}

      @site_users = {} # Cache for the registered users of my site, not Discord.
      @tokens = {}
    end

    def user(id) end

    def site_user(uuid)
      return @site_users[uuid] if @site_users[uuid]
      
      puts "UUID: #{uuid}"

      # get from db
      db_user = Discord::Database.get_user(uuid)

      return nil if db_user.nil?

      puts db_user

      user = SiteUser.new(db_user['name'], db_user['discriminator'], db_user['email'], db_user['uid'])
      @site_users[uuid] = user
    end

    def insert_user(uuid, user)
      return @site_users[uuid] if @site_users[uuid]

      @site_users[uuid] = user
    end

    def guild(id) end

    def channel(id) end

    def token(uid)
      return @tokens[uid] if @tokens[uid]

      print "UID: #{uid}"

      # query db
      token_data = Discord::Database.get_token(uid)

      return nil if token_data.nil? || token_data['token'].nil?

      token = Discord::Token.new(token_data['token'], token_data['refresh_token'], token_data['expires_at'])
      @tokens[uid] = token
    end

    def token_data_from_token(old_token)
      token_data = @tokens.select { |tdata| tdata.token == old_token }

      token_data
    end
  end
end
