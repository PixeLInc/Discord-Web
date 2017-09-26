module Discord
  module Middleware
    require 'sinatra/base'

    # Provides error handling for each route it's used on
    class ErrorHandler < Sinatra::Base
      set :static, true
      set :public_folder, 'public'

      error 403 do
        redirect '/errors/not_authorized.html'
      end

      error 404 do
        redirect '/errors/not_found.html'
      end
    end
  end
end
