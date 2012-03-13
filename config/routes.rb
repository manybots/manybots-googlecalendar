ManybotsGooglecalendar::Engine.routes.draw do
  resources :calendar do
    collection do
      get 'callback'
    end
    member do
      post 'import'
    end
  end
  
  root :to => 'calendar#index'
  
end
