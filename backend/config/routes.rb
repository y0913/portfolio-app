Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    get "hello", to: "hello#index"

    resource :session, only: [:show, :create, :destroy]
    resources :users, only: [:create]
    resources :documents, only: [:index, :show, :create, :destroy]
  end
end
