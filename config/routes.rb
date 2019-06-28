Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  namespace :api do
    namespace :v1 do
      resources :customers do
        resources :orders, only: [:index, :create]
      end
      resources :orders, only: [:index, :show] do
        post :ship, on: :member
        resources :products, only: [:index, :create]
      end
      resources :products, only: [:index, :show]
    end
  end
end
