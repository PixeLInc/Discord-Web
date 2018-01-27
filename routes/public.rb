module Discord
  require 'sinatra/base'
  require_relative '../middleware/base_controller.rb'

  # Protected user routes
  class Public < Discord::Middleware::BaseController
    get '/' do
      redirect '/discord.html'
    end
  end
end
