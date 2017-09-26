require_relative 'routes/authed.rb'
require_relative 'routes/public.rb'

run Rack::URLMap.new({
  "/" => Discord::Public,
  "/user" => Discord::UserRoute
})