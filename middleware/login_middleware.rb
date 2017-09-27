module Discord
  module Middleware
    # Provides a Login Middleware to make sure every request is authenticated.
    class Login < Discord::Middleware::BaseController
      def registered?
        uuid = request.cookies['useruid']

        return false unless uuid

        session[:user_authed] = Discord::Database.valid_uuid?(uuid) unless session[:user_authed]

        session[:user_authed]
      end

      before do # Check before any request using this
        halt 403 unless registered?
      end
    end
  end
end
