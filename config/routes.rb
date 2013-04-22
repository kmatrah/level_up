LevelUp::Engine.routes.draw do
  root to: "home#index"

  resources :jobs do
    member do
      post "unqueue"
      post "run"
      post "reboot"
      post "move"
      get "graphviz"
    end
  end

  resources :flowcharts, only: [:index, :show] do
    get "graphviz", on: :member
  end
end
