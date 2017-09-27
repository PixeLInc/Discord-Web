module Discord
  require 'sinatra/base'
  require_relative '../middleware/base_controller.rb'

  # Protected user routes
  class UserRoute < Discord::Middleware::BaseController
    require_relative '../middleware/login_middleware'

    use Discord::Middleware::Login # Everything will be protected by auth

    get '/' do # It will go by '/user/*'
      redirect '/user/profile'
    end

    get '/profile' do
      @site_user = Discord::Cache.site_user(request.cookies['useruid'])

      return 'Error getting site user: #PRF34' if @site_user.nil?

      @user_info = Discord::Cache.user(@site_user.uid)

      haml :profile
    end

    get '/guilds' do
      @site_user = Discord::Cache.site_user(request.cookies['useruid'])

      return 'Error getting site user: #PRF34' if @site_user.nil?

      user_token = Discord::Cache.token(@site_user.uid)

      return 'Error getting auth' if user_token.nil?

      @guilds = OAuth.guilds(user_token.token) # Who needs caching? Am I right, or am I right?

      haml :guilds
    end

    get '/guilds/:id' do
      return 'Guild ID not set' if params[:id].nil?

      @guild = Discord::Cache.guild(params[:id])

      puts @guild.icon_url

      haml :guild
    end

    get '/refresh' do
      return 403 if params[:uid].nil? || params[:uuid].nil? # lul

      Discord::Cache.user(params[:uid], true)
      Discord::Cache.site_user(params[:uuid], true)

      redirect '/user/profile'
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

      auth = OAuth.post('/oauth2/token', data, false)

      raise "Error getting token from Discord: #{auth}" if auth.nil? || auth['access_token'].nil? || auth['refresh_token'].nil?

      user_data = OAuth.user_info(auth['access_token'])

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
