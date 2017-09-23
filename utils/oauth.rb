class OAuth
  require 'httparty'

  CONFIG = JSON.parse(File.read('config.json')) # too lazy 4 error checking | IN OAuth cus im lazy and its easier lol..

  CLIENT_ID = CONFIG['client_id']
  CLIENT_SECRET = CONFIG['client_secret']

  CALLBACK_URL = 'http://localhost:4567/auth/discord/callback'.freeze

  BASE_URL = 'https://discordapp.com/api/v6'.freeze

  def self.user_info(token)
    puts "TOKEN NIL?: #{token.nil?}"
    get('/users/@me', token, 'http://localhost:4567/profile')
  end

  def self.guilds(token)
    get('/users/@me/guilds', token, 'http://localhost:4567/guilds')
  end

  def self.get(endpoint, token, redir)
    return 'Unauthorized Token' if token.nil?

    url = "#{BASE_URL}#{endpoint}"
    headers = {
      'Authorization': "Bearer #{token}"
    }

    response = HTTParty.get(url, headers: headers)

    return get(endpoint, refresh_token(redir, token), redir) if response.code == 401 # Re KURRRR SHONNNNNNNNNNNNNNNNNN

    JSON.parse(response.body)
  end

  def self.post(endpoint, data)
    url = "#{BASE_URL}#{endpoint}"

    headers = {
      'Content-Type': 'application/x-www-form-urlencoded'
    }

    response = HTTParty.post(url, body: data, headers: headers)

    return "ERROR: #{response.body}" if response.code == 401

    JSON.parse(response.body)
  end

  def self.refresh_token(previous_uri, old_token)
    refresh_data = Database.get_refresh_data_from_token(old_token)

    return nil if refresh_data.nil?
    return nil if refresh_data['refresh_token'].nil?

    # Let's check to see if the token even needs to be refreshed and its not just an invalid endpoint
    expires_at = Time.at((DateTime.now + refresh_data['expires_at']).to_time.to_i)
    return nil if expires_at > Time.now # Token does not need to be refreshed

    data = {
      'client_id' => CLIENT_ID,
      'client_secret' => CLIENT_SECRET,
      'grant_type' => 'refresh_token',
      'refresh_token' => refresh_data['refresh_token'],
      'redirect_uri' => previous_uri
    }

    jsun = post('/oauth/token', data)

    return "Json Error: #{jsun}" if jsun['access_token'].nil?

    # Replace in database
    Database.add_token_or_update(refresh_data['uid'], jsun['access_token'], jsun['refresh_token'], jsun['expires_in'])

    jsun['access_token'] # return with the token so we can retry the request?
  end
end
