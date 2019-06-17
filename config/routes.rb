Rails.application.routes.draw do
  get 'events/index'
  get 'events/show'
  get 'events/new'
  get 'events/edit'
  get 'events/create'
  get 'events/update'
  get 'events/destroy'
  match "/login", to: 'session#create', as: :log_in, via: [:get, :post]
  get '/logout', to: 'session#destroy'
  get 'dashboard/index'

  root "dashboard#index"
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
