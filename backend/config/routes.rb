Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    get "hello", to: "hello#index"

    resource :session, only: [:show, :create, :destroy]
    resources :users, only: [:create]
  end
end
