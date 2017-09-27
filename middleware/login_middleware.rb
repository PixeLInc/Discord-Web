module Discord
  module Middleware
    # Provides a Login Middleware to make sure every request is authenticated.
    class Login < Discord::Middleware::BaseController
      def registered?
        uid = request.cookies['useruid']

        return false unless uid

        session[:user_authed] = false

        # session[:user_authed] = Database::Database.valid_uuid?(uid) unless session[:user_authed]

        session[:user_authed]
      end

      before do # Check before any request using this
        halt 403 unless registered?
      end
    end
  end
end
