Rahvakogu::Application.routes.draw do
  resources :categories do
    resources :ideas
  end

  resources :export

  match "/groups/suggest_user" => "groups#suggest_user"
  match "/ideas/flag/:id" => "ideas#flag"
  match "/ideas/abusive/:id" => "ideas#abusive"
  match "/ideas/not_abusive/:id" => "ideas#not_abusive"
  match "/admin/all_flagged" => "admin#all_flagged"
  match "/admin/all_deleted" => "admin#all_deleted"

  resources :groups

  resources :pages do
    member do
      post :add_comment
    end
    resources :pagecomments do
      member do
        get :hide_comment
      end
    end
  end

  resources :sub_instances do
    member do
      get :email
      get :picture
      put :picture_save
    end
  end

  resources :news, :except => [:show]

  devise_for :users,
    :controllers => {
      :registrations => "users/registrations",
      :omniauth_callbacks => "users/sessions"
    },
    :skip => [:sessions]

  devise_scope :user do
    controller "users/sessions" do
      get "/signin"  => :new, :as => :new_user_session
      get "/signout" => :destroy, :as => :destroy_user_session
    end
  end

  resources :users, :except => [:new, :create, :destroy]

  resources :settings do
    collection do
      get :signups
      get :picture
      put :picture_save
      get :delete
    end
  end

  resources :ideas do
  	member do
      get :statistics
      put :flag_inappropriate
      get :flag
      put :bury
      put :compromised
      put :successful
      put :failed
      put :intheworks

      post :endorse
      post :oppose

      get :endorsed
      get :opposed
      get :activities
      get :endorsers
      get :opposers
      get :discussions
      put :create_short_url
      post :tag
      put :tag_save
      get :points
      get :opposer_points
      get :endorser_points
      get :neutral_points
      get :everyone_points
      get :top_points
      get :endorsed_points
      get :opposed_top_points
      get :endorsed_top_points
      get :comments
      get :documents
  	end

  	collection do
      get :pending

      get :minu
      get :yours_finished
      get :yours_top
      get :yours_lowest
      get :yours_created
      get :network
      get :consider
      get :finished
      get :top
      get :top_24hr
      get :top_7days
      get :top_30days
      get :rising
      get :falling
      get :controversial
      get :random
      get :newest
      get :bottom
      get :untagged
      get :revised
  	end

    resources :changes do
      member do
        put :start
        put :stop
        put :approve
        put :flip
        get :activities
      end
      resources :votes
    end

    resources :idea_revisions do
      member do
        get :clean
        get :show
      end

    end

    resources :points
  end

  resources :activities do
    member do
      put :undelete
      get :unhide
    end

    resources :following_discussions, :as=>"followings"

    resources :comments do
      collection do
        get :more
      end

      member do
        get :unhide
        get :flag
        post :not_abusive
        post :abusive
      end
    end
  end

  resources :points do
    member do
      get :flag
      post :not_abusive
      post :abusive
      get :activity
      get :discussions
      post :quality
      post :unquality
      get :unhide
    end

    collection do
      get :newest
      get :revised
      get :your_ideas
      get :your_index
    end

    resources :revisions do
      member do
        get :clean
      end
    end
  end

  resources :color_schemes do
    collection do
      put :preview
    end
  end

  resources :instances do
    member do
      get :apis
    end
  end

  resources :searches do
    collection do
      get :all
    end
  end

  resources :endorsements
  resources :tags
  resource :session
  resources :delayed_jobs do
    member do
      get :top
      get :clear
    end
  end

  match "/" => "home#index", :as => :root

  match "/activate/:activation_code" => "users#activate",
    :as => :activate, :activation_code => nil
  match "/signup" => "users#new", :as => :signup
  match "/logout" => "sessions#destroy", :as => :logout
  match "/unsubscribe" => "unsubscribes#new", :as => :unsubscribe
  match "/hot" => "ideas#hot"
  match "/cold" => "ideas#cold"
  match "/new" => "ideas#new"
  match "/controversial" => "ideas#controversial"
  match "/vote/:action/:code" => "vote#index"
  match "/search" => "searches#index"
  match "/splash" => "splash#index"

  match "/issues" => "issues#index"
  match "/issues.:format" => "issues#index"
  match "/issues/:id" => "issues#show", as: "issue"
  match "/issues/:id.:format" => "issues#show"
  match "/issues/:id/:action" => "issues#index", :as => :filtered_issue
  match "/issues/:id/:action.:format" => "issues#index"

  match "/pictures/:short_name/:action/:id" => "pictures#index"
  match ":controller" => "#index"
  match ":controller/:action" => "#index"
  match ":controller/:action.:format" => "#index"
  match "/:controller(/:action(/:id))"
end
