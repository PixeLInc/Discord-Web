module Discord
  # Provides a simple cache for my site
  module Cache
    extend self

    require_relative 'discord_user'
    require_relative 'discord_guild'
    require_relative 'site_user'
    require_relative 'token'
    require_relative 'permissions'

    def init
      @users = {}
      @guilds = {}
      @channels = {}

      @site_users = {} # Cache for the registered users of my site, not Discord.
      @tokens = {}
    end

    def user(id, force = false)
      return @users[id] if @users[id] && !force
      puts "Resolving uncached user '#{id}'..."
      # We need a uuid, sooo let's get it. |
      user_token = token(id)

      return nil if user_token.nil?

      user_jsun = OAuth.user_info(user_token.token)

      Discord::Database.update_user(id, user_jsun)

      user = DiscordUser.new(user_jsun['username'], user_jsun['discriminator'], user_jsun['email'], user_jsun['id'], user_jsun['avatar'], user_jsun['bot'].nil? ? false : true, user_jsun['mfa_enabled'], user_jsun['verified'])
      @users[id] = user
    end

    def site_user(uuid, force = false)
      return @site_users[uuid] if @site_users[uuid] && !force

      # get from db
      db_user = Discord::Database.get_user(uuid)

      return nil if db_user.nil?

      user = SiteUser.new(db_user['name'], db_user['discriminator'], db_user['email'], db_user['uid'], db_user['created_at'], db_user['updated_at'], db_user['mfa_enabled'])
      @site_users[uuid] = user
    end

    def insert_user(uuid, user)
      return @site_users[uuid] if @site_users[uuid]

      @site_users[uuid] = user
    end

    def user_guilds(uid, force = false)
      return user(uid).guild_ids if user(uid)

      user_token = token(uid)

      return unless user_token.nil?

      guilds_json = OAuth.guilds(user_token.token)

      user_data = user(id)

      return if user_data.nil?

      guilds_json.each do |guild|
        user_data.guilds_ids.push(guild['id'])
      end

    end

    def guilds(token, force = false)
      guild_json = OAuth.guilds(token)

      return nil if guild_json.is_a?(String)

      guild_json.select {|guild| Permissions.has_perm(guild["permissions"], Permissions::PERMS[:manage_guilds])}
    end

    def guild(token, id, force = false)
      return @guilds[id] if @guilds[id] && !force

      puts "Resolving uncached guild '#{id}...'"

      guild_json = OAuth.get_guild(token, id)

      if guild_json["code"] == 50001
        return 50001
      end

      guild = DiscordGuild.new(guild_json['id'], guild_json['name'], guild_json['icon'], guild_json['owner_id'], guild_json['roles'], guild_json['emojis'], guild_json['unavailable'], guild_json['member_count'], guild_json['members'], guild_json['channels'])

      @guilds[id] = guild
    end

    def channel(id) end

    def token(uid)
      return @tokens[uid] if @tokens[uid]

      # query db
      token_data = Discord::Database.get_token(uid)

      return nil if token_data.nil? || token_data['token'].nil?

      token = Token.new(token_data['token'], token_data['refresh_token'], token_data['expires_at'])
      @tokens[uid] = token
    end

    def token_data_from_token(old_token)
      token_data = @tokens.find { |tdata| tdata == old_token }

      token_data
    end
  end
end
