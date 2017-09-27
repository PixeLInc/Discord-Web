require_relative 'models/oauth'
require_relative 'models/database'

require 'sinatra'

require 'securerandom'
require 'json'

enable :sessions
set :show_exceptions, false

get '/' do
  redirect '/discord.html'
end

get '/auth/discord' do # for inside of discord.html for easierness
  redirect "https://discordapp.com/api/oauth2/authorize?response_type=code&client_id=#{OAuth::CLIENT_ID}&scope=#{SCOPES}&redirect_uri=#{OAuth::CALLBACK_URL}"
end

get '/auth/discord/callback' do # Callback
  return 'Error' if params[:code].nil?

  data = {
    'client_id' => OAuth::CLIENT_ID,
    'client_secret' => OAuth::CLIENT_SECRET,
    'grant_type' => 'authorization_code',
    'code' => params[:code],
    'redirect_uri' => OAuth::CALLBACK_URL
  }

  auth = OAuth.post('/oauth2/token', nil, data, nil)

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

get '/auth/failure' do
  "<pre>#{params[:message]}</pre>"
end
