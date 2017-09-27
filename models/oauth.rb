module Discord
  # Provides access to the discord API
  class OAuth
    require 'httparty'

    CONFIG = JSON.parse(File.read('config.json')) # too lazy 4 error checking | IN OAuth cus im lazy and its easier lol..

    CLIENT_ID = CONFIG['client_id']
    CLIENT_SECRET = CONFIG['client_secret']

    CALLBACK_URL = 'http://localhost:4567/discord/callback'.freeze

    BASE_URL = 'https://discordapp.com/api/v6'.freeze

    def self.user_info(token)
      get('/users/@me', token, false)
    end

    def self.guilds(token)
      get('/users/@me/guilds', token, false)
    end

    def self.get(endpoint, token, bot = false)
      return 'Unauthorized Token' if token.nil? && !bot

      url = "#{BASE_URL}#{endpoint}"
      headers = {
        'Authorization': token
      }

      response = HTTParty.get(url, headers: headers)

      return get(endpoint, refresh_token(token)) if response.code == 401 # Re KURRRR SHONNNNNNNNNNNNNNNNNN

      JSON.parse(response.body)
    end

    def self.post(endpoint, data, bot = false)
      url = "#{BASE_URL}#{endpoint}"

      headers = {
        'Content-Type': 'application/x-www-form-urlencoded'
      }

      headers['Authorization'] = CONFIG['bot_token'] if bot

      response = HTTParty.post(url, body: data, headers: headers)

      return "ERROR: #{response.body}" if response.code == 401

      JSON.parse(response.body)
    end

    def self.refresh_token(old_token)
      token_data = Discord::Cache.token_data_from_token(old_token)

      return nil if token_data.nil?
      return nil if token_data.refresh_token.nil?

      # Let's check to see if the token even needs to be refreshed and its not just an invalid endpoint
      return nil unless token_data.expired?

      data = {
        'client_id' => CLIENT_ID,
        'client_secret' => CLIENT_SECRET,
        'grant_type' => 'refresh_token',
        'refresh_token' => token_data.refresh_token
      }

      jsun = post('/oauth/token', data)

      return "Json Error: #{jsun}" if jsun['access_token'].nil?

      access_token = jsun['access_token']
      refresh_token = jsun['refresh_token']
      expires_in = jsun['expires_in']

      # Replace in database
      Database.add_token_or_update(refresh_data['uid'], access_token, refresh_token, expires_in)
      # Update cache
      new_data = {
        token: access_token,
        refresh: refresh_token,
        expires: expires_in
      }

      Discord::Cache.update_token(token_data.uid, new_data)

      access_token # return with the token so we can retry the request?
    end
  end
end
