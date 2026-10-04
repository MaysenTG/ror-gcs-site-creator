Rails.application.routes.draw do
  mount ActionCable.server => "/cable"

  # Fly.io / load-balancer health check
  get "/up", to: ->(_env) { [200, { "Content-Type" => "text/plain" }, ["OK"]] }

  draw :published_sites
  draw :checkout

  devise_for :accounts, controllers: { registrations: "registrations" }

  draw :admin
  draw :internal

  get "home/pricing", to: "home#pricing"
  get "pricing", to: "home#pricing"
  root "home#show"
end
