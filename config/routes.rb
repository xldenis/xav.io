Xavio::Application.routes.draw do
  root :to=> "posts#index"
  resources :posts
  get 'posts/tag/:tag' => 'posts#tag',:as=>:post_tag
  get '/auth/github/callback' => "sessions#create"
  get '/signin' => "sessions#new", :as => :signin
  end
