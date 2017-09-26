module Discord
  module Middleware
    require 'sinatra/base'

    # Provides a Login Middleware to make sure every request is authenticated.
    class Login < Sinatra::Base
      enable :sessions

      def registered?
        uid = request.cookies['useruid']

        return false unless uid

        session[:user_authed] = true

        # session[:user_authed] = Database::Database.valid_uuid?(uid) unless session[:user_authed]

        session[:user_authed]
      end

      before do # Check before any request using this
        halt 403, 'Not authorized' unless registered?
      end
    end
  end
end
