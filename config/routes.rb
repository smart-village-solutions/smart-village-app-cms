# frozen_string_literal: true

Rails.application.routes.draw do
  resources :news_items
  resources :tours
  resources :point_of_interests
  resources :events
  resources :waste_calendar
  resources :jobs
  resources :offers
  resources :surveys
  get "/data_provider", to: "data_provider#edit"
  get "/visibility/:item_type/:id/:visible", to: "data_provider#visibility"
  patch "/data_provider", to: "data_provider#update"
  match "/login", to: "session#create", as: :log_in, via: %i[get post]
  get "/logout", to: "session#destroy"
  get "dashboard/index"

  root "dashboard#index"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
