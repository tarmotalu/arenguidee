Arenguidee::Application.routes.draw do
  devise_for :users,
    :controllers => {:omniauth_callbacks => "users/sessions"},
    :skip => [:sessions, :registrations]

  devise_scope :user do
    controller "users/sessions" do
      get "/signin"  => :new, :as => :new_user_session
      get "/signout" => :destroy, :as => :destroy_user_session
      get "/users/auth/failure" => :failure if Rails.env.test?
    end
  end

  resources :users, :except => [:new, :create, :destroy]

  resources :categories do
    resources :ideas
  end

  resources :pages
  resources :news, :except => [:show]

  resources :ideas do
    member do
      post :endorse
      post :oppose
    end

    collection do
      get :pending
    end

    resources :points
  end

  resources :points
  resources :endorsements

  match "/issues" => "issues#index"
  match "/issues.:format" => "issues#index"
  match "/issues/:id" => "issues#show", :as => "issue"
  match "/issues/:id.:format" => "issues#show"
  match "/issues/:id/:action" => "issues#index", :as => :filtered_issue
  match "/issues/:id/:action.:format" => "issues#index"

  root :to => "home#index"
end
