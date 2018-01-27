module Discord
  require 'sinatra/base'
  require_relative '../middleware/base_controller.rb'
  require_relative '../models/tfa.rb'

  # Protected user routes
  class UserRoute < Discord::Middleware::BaseController
    require_relative '../middleware/login_middleware'
    require_relative '../middleware/mfa_middleware'

    use Discord::Middleware::Login # Everything will be protected by auth
    use Discord::Middleware::MFA # TFA DADDY!?

    get '/?' do # It will go by '/user/*'
      redirect '/user/profile'
    end

    post '/verify/?' do # Let's check if 2FA enabled & stuff
      code = params[:code]

      halt 403 if code.nil?

      uuid = request.cookies['useruid']

      # First, we need to get an rotp obj with their secret
      mfa_data = TFA.get_secret(uuid)

      halt 403 if mfa_data.nil? # This should NEVER happen (unless they're doing it manually)

      rotp = TFA.rotp(mfa_data) # TODO: Change when working with array

      # This should return true or false
      is_valid = TFA.verify_code(rotp, code)

      puts "User has valid code?: #{is_valid}"
      session[:mfa_authed] = is_valid

      halt haml :tfa unless is_valid

      # TODO: Add a redirect_uri to put them back on their previous page.
      redirect '/discord.html'
    end

    get '/mfa/?' do
      # Show all user settings for 2FA and such.

    end

    get '/profile/?' do
      @site_user = Discord::Cache.site_user(request.cookies['useruid'])

      return 'Error getting site user: #PRF34' if @site_user.nil?

      @user_info = Discord::Cache.user(@site_user.uid)

      haml :profile
    end

    get '/guilds/?' do
      redirect "/user/guilds/#{params[:guild_id]}" if params[:guild_id]

      @site_user = Discord::Cache.site_user(request.cookies['useruid'])

      return 'Error getting site user: #PRF34' if @site_user.nil?

      user_token = Discord::Cache.token(@site_user.uid)

      return 'Error getting auth' if user_token.nil?

      @guilds = Discord::Cache.guilds(user_token.token) # Who needs caching? Am I right, or am I right?

      return 'Not Authorized' if @guilds.nil?

      haml :guilds
    end

    get '/guilds/:id/?' do
      return 'Guild ID not set' if params[:id].nil?

      site_user = Discord::Cache.site_user(request.cookies['useruid'])
      user_token = Discord::Cache.token(site_user.uid)

      return "Failed to auth" if user_token.nil?

      @guild = Discord::Cache.guild(user_token.token, params[:id])

      redirect "/discord/auth/#{params[:id]}" if @guild == 50001

      puts @guild.icon_url unless @guild == 50001

      haml :guild
    end

    get '/refresh/?' do
      return 403 if params[:uid].nil? || params[:uuid].nil? # lul

      Discord::Cache.user(params[:uid], true)
      Discord::Cache.site_user(params[:uuid], true)

      redirect '/user/profile'
    end
  end

  # Callbacks and methods for Discord authorization
  class DiscordAuthRoute < Discord::Middleware::BaseController
    SCOPES = 'identify email guilds'.freeze

    get '/auth/?' do
      redirect "https://discordapp.com/api/oauth2/authorize?response_type=code&client_id=#{OAuth::CLIENT_ID}&scope=#{SCOPES}&redirect_uri=#{OAuth::CALLBACK_URL}"
    end

    get '/auth/:id/?' do
      return "Invalid ID Specified" unless params[:id]

      redirect "https://discordapp.com/oauth2/authorize?&client_id=#{OAuth::CLIENT_ID}&scope=bot&permissions=8&guild_id=#{params[:id]}&redirect_uri=http://localhost:4567/user/guilds"
    end

    get '/callback/?' do
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
      expiry = auth['expires_in']

      Discord::Database.insert_token(uid, token, refresh, expiry)

      # Expiry
      cookie_expires = Date.today

      response.set_cookie('useruid', value: uuid, domain: FALSE, path: '/', expires: (cookie_expires + 30).to_time)

      redirect '/discord.html'
    end

    get '/failure/?' do
      "<pre>#{params[:message]}</pre>"
    end
  end
end
