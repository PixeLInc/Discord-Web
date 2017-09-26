module Discord
  require 'sinatra/base'
  require_relative '../middleware/error_handler_middleware.rb'
  
  # Protected user routes
  class Public < Discord::Middleware::ErrorHandler

    get '/' do
      'Welcome to PixeLInc!'
    end
  end
end
