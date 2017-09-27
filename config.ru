require_relative 'routes/authed.rb'
require_relative 'routes/public.rb'
require_relative './models/cache.rb'

Discord::Cache.init

run Rack::URLMap.new({
  "/" => Discord::Public,
  "/user" => Discord::UserRoute,
  "/discord" => Discord::DiscordAuthRoute
})