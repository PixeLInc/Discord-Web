module Discord
  require 'sinatra/base'
  require_relative '../middleware/error_handler_middleware.rb'

  # Protected user routes
  class UserRoute < Discord::Middleware::ErrorHandler
    require_relative '../middleware/login_middleware'

    use Discord::Middleware::Login # Everything will be protected by auth

    get '/' do # It will go by '/user/*'
      'You can only see this when authed.'
    end
  end
end
