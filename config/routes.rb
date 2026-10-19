Rails.application.routes.draw do
  root "checklists#index"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "signup", to: "users#new"
  post "signup", to: "users#create"

  resources :checklists, path: "sessions", only: [:index, :show, :create, :update] do
    resources :join_requests, only: [:create, :update]
    resources :items, only: [:create, :update, :destroy] do
      member do
        post :lock
        delete :unlock
      end
    end
  end

  mount ActionCable.server, at: "/cable"
end
