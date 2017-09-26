module Discord
  # Provides access to the database
  module Database
    require 'mysql2'

    DB = Mysql2::Client.new(host: OAuth::CONFIG['database']['host'], username: OAuth::CONFIG['database']['username'], password: OAuth::CONFIG['database']['password'], database: OAuth::CONFIG['database']['db'])

    def self.insert_user(uid, name, discrim, email, uuid)
      cached_user = Discord::Cache.site_user(uid)

      return cached_user if cached_user

      # TODO: Update cache with data
      return DB.query("UPDATE `user_data` SET uuid='#{uuid}', name='#{name}', email='#{email}', created_at='#{Time.now}' where uid='#{uid}'") if user_exists?(uid) # UID should NEVAR change

      DB.query("INSERT IGNORE INTO `user_data` (uid, uuid, name, discriminator, email, created_at) VALUES ('#{uid}', '#{uuid}', '#{name}', '#{discrim}', '#{email}', '#{Time.now}');")
    end

    def self.insert_token(uid, token, refresh, exp)
      cached_token = Discord::Cache.token(uid)

      return cached_token if cached_token
      # TODO: Update cache with data

      return DB.query("UPDATE `token_data` SET token='#{token}', refresh_token='#{refresh}', expires_at='#{exp}' where uid='#{uid}'") if user_has_token?(uid)

      DB.query("INSERT IGNORE INTO `token_data` (uid, token, refresh_token, expires_at) VALUES ('#{uid}', '#{token}', '#{refresh}', '#{exp}');")
    end

    def self.user_exists?(uid)
      # Check cache, then make the query if they're not in there.
      results = DB.query("SELECT uid FROM `user_data` WHERE uid='#{uid}'")
      results.count != 0
    end

    def self.token_exists?(token)
      # Check cache then make query if it's not in there.
      res = DB.query("SELECT token FROM `token_data` WHERE token='#{token}'")
      res.count != 0
    end

    def self.user_has_token?(uid)
      res = DB.query("SELECT token FROM `token_data` WHERE uid='#{uid}'")
      res.count != 0
    end

    def self.get_uid_from_uuid(uuid)
      res = DB.query("SELECT uid FROM `user_data` WHERE uuid='#{uuid}'")
      res.first['uid']
    end

    def self.get_token(uid)
      res = DB.query("SELECT token FROM `token_data` WHERE uid='#{uid}'")
      res.first['token']
    end

    def self.get_refresh_data_from_token(token)
      res = DB.query("SELECT expires_at, refresh_token, uid  FROM `token_data` WHERE token='#{token}'")
      res.first
    end

    def self.valid_uuid?(uuid)
      res = DB.query("SELECT uuid FROM `user_data` WHERE uuid='#{uuid}'")
      res.count != 0
    end

    def self.get_user(uuid)
      res = DB.query("SELECT uid, name, discriminator, email, created_at FROM `user_data` WHERE uuid='#{uuid}'")
      res.first
    end
  end
end
