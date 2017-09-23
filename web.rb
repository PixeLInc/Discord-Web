require_relative 'utils/oauth.rb'
require './utils/database'

require 'sinatra'
require 'sinatra/cookies'

require 'securerandom'
require 'json'

use Rack::Session::Cookie, key: 'rack.session', expire_after: 2592000, secret: OAuth::CONFIG['rake_secret']

enable :sessions
set :show_exceptions, false

SCOPES = 'identify email guilds'.freeze

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

  Database.add_user_or_update(uid, username, discriminator, email, uuid)

  # Token
  token = auth['access_token']
  refresh = auth['refresh_token']
  expiry = auth['expires_at']

  Database.add_token_or_update(uid, token, refresh, expiry)

  # Expiry
  cookie_expires = Date.today

  response.set_cookie('useruid', value: uuid, domain: FALSE, path: '/', expires: (cookie_expires + 30).to_time)

  redirect '/discord.html'
end

get '/auth/failure' do
  "<pre>#{params[:message]}</pre>"
end

get '/profile' do
  return 403 unless registered?

  uid = Database.get_uid_from_uuid(request.cookies['useruid'])
  user_token = Database.get_token(uid)

  return 'Invalid Response' if user_token.nil?

  @user_info = OAuth.user_info(user_token)

  erb :profile
end

get '/guilds' do
  return 403 unless registered?

  uid = Database.get_uid_from_uuid(request.cookies['useruid'])
  user_token = Database.get_token(uid)

  return 'Invalid Response' if user_token.nil?

  @guilds = OAuth.guilds(user_token)

  erb :guilds
end

get '/moaraccess' do
  return 403 unless registered?

  uid = Database.get_uid_from_uuid(request.cookies['useruid'])

  # Get sgm member
  return 403 unless is_sgm_member?(uid)

  @smember = get_sgm_member(uid)

  erb :moarpls
end

get '/refresh' do
  return 403 unless registered?

  uid = Database.get_uid_from_uuid(request.cookies['useruid'])
  user_token = Database.get_token(uid)

  return 'Invalid Response' if user_token.nil?

  return 'Unauthorized' if OAuth.refresh_token('/discord.html', user_token).nil?
end

not_found do
  erb :not_found
end

error 403 do
  erb :not_authorized
end

def registered? # Set permission level
  uid = request.cookies['useruid']

  return false unless uid

  session[:user_authed] = Database.valid_uuid?(uid) unless session[:user_authed] || session[:user_authed] == false

  session[:user_authed]
end

def authorized?(_uid)
  return false unless registered?
  # Do permission check here
  true
end
