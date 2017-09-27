module Discord
  require 'sinatra/base'
  require_relative '../middleware/base_controller.rb'

  # Protected user routes
  class UserRoute < Discord::Middleware::BaseController
    require_relative '../middleware/login_middleware'

    use Discord::Middleware::Login # Everything will be protected by auth

    get '/' do # It will go by '/user/*'
      'You can only see this when authed.'
    end
  end

  # Callbacks and methods for Discord authorization
  class DiscordAuthRoute < Discord::Middleware::BaseController
    SCOPES = 'identify email guilds'.freeze

    get '/auth' do
      redirect "https://discordapp.com/api/oauth2/authorize?response_type=code&client_id=#{OAuth::CLIENT_ID}&scope=#{SCOPES}&redirect_uri=#{OAuth::CALLBACK_URL}"
    end

    get '/callback' do
      return 'Error' if params[:code].nil?

      data = {
        'client_id' => OAuth::CLIENT_ID,
        'client_secret' => OAuth::CLIENT_SECRET,
        'grant_type' => 'authorization_code',
        'code' => params[:code],
        'redirect_uri' => OAuth::CALLBACK_URL
      }

      puts "CALLBACK DATA: #{data}"

      auth = OAuth.post('/oauth2/token', data, false)

      puts "AUTH: #{auth}"

      raise "Error getting token from Discord: #{auth}" if auth.nil? || auth['access_token'].nil? || auth['refresh_token'].nil?

      user_data = OAuth.user_info(auth['access_token'])

      puts "USER_DATA: #{user_data}"

      raise "Error getting user data from Discord: #{user_data}" if user_data.nil? || user_data['username'].nil?

      username = user_data['username']
      discriminator = user_data['discriminator']
      email = user_data['email']
      uid = user_data['id']

      uuid = SecureRandom.uuid

      Discord::Database.insert_user(uid, username, discriminator, email, uuid)

      # Token
      token = auth['access_token']
      refresh = auth['refresh_token']
      expiry = auth['expires_at']

      Discord::Database.insert_token(uid, token, refresh, expiry)

      # Expiry
      cookie_expires = Date.today

      response.set_cookie('useruid', value: uuid, domain: FALSE, path: '/', expires: (cookie_expires + 30).to_time)

      redirect '/discord.html'
    end

    get '/failure' do
      "<pre>#{params[:message]}</pre>"
    end
  end
end
