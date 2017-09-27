module Discord
  module Middleware
    require 'sinatra/base'
    # Easiest way to get access to everything and have error handling
    class BaseController < Sinatra::Base
      require 'sinatra/cookies'
      require 'rack/protection'

      require_relative '../models/oauth'
      require_relative '../models/database'

      enable :sessions

      use Rack::Protection # Provides basic needed protection against web attacks
      use Rack::Session::Cookie, key: 'rack.session', expire_after: 2592000, secret: OAuth::CONFIG['rake_secret']

      set :static, true
      set :public_folder, 'public'
      set :views, File.expand_path('../../views', __FILE__)

      error 403 do
        haml :not_authorized
      end

      not_found do
        redirect '/errors/not_found.html'
      end
    end
  end
end
