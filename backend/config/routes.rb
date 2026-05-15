Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    get "hello", to: "hello#index"

    resource :session, only: [:show, :create, :destroy]
    resources :users, only: [:create]
    resources :documents, only: [:index, :show, :create, :destroy]
    resources :chat_sessions, only: [:index, :show, :create, :destroy] do
      resources :messages, only: [:create] do
        collection do
          post :stream
        end
      end
    end

    # Inbound webhooks from external messaging platforms.
    # Authenticated per-platform via signature header, not user session.
    namespace :webhooks do
      post :chatwork, to: "chatwork#create"
    end
  end
end
