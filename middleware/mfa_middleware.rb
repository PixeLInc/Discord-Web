module Discord
  module Middleware

    class MFA < Discord::Middleware::BaseController

      require_relative '../models/tfa.rb'

      def verified?
        return false if request.path_info == '/verify'
        uuid = request.cookies['useruid']

        return false if uuid.nil?

        return true if session[:mfa_authed]

        puts "AYLMAO"

        mfa_data = TFA.get_secret(uuid)

        if mfa_data.nil? # They don't have 2fa enabled.
          puts 'lksndf'
          session[:mfa_authed] = true
          return true
        end

        puts 'YES'

        halt haml :tfa unless session[:mfa_authed]

        session[:mfa_authed]
      end

      before do
        verified?
      end
    end
  end
end
