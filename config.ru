require "zou"

Sinatra::Base.set(:run, false)
Sinatra::Base.set(:environment, :production)

run Sinatra::Application
