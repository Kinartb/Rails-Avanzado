Myrottenpotatoes::Application.routes.draw do
  get 'auth/:provider/callback' => 'sessions#create'
  get 'auth/failure' => 'sessions#failure'
  get 'auth/twitter', as: 'login'
  post 'logout' => 'sessions#destroy'
  resources :movies
  root to: redirect('/movies')
end
