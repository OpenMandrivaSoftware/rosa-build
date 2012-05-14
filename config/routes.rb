# -*- encoding : utf-8 -*-
Rosa::Application.routes.draw do
  devise_scope :users do
    get '/users/auth/:provider' => 'users/omniauth_callbacks#passthru'
  end
  devise_for :users, :controllers => {:omniauth_callbacks => 'users/omniauth_callbacks'}

  resources :search, :only => [:index]

  get '/forbidden' => 'pages#forbidden', :as => 'forbidden'
  get '/terms-of-service' => 'pages#tos', :as => 'tos'

  get '/activity_feeds.:format' => 'activity_feeds#index', :as => 'atom_activity_feeds', :format => /atom/
  if APP_CONFIG['anonymous_access']
    authenticated do
      root :to => 'activity_feeds#index'
    end
    root :to => 'pages#root'
  else
    root :to => 'activity_feeds#index'
  end

  scope :module => 'platforms' do
    resources :platforms do
      resources :private_users, :except => [:show, :destroy, :update]
      member do
        get    :clone
        get    :members
        post   :remove_members
        delete :remove_member
        post   :add_member
        post   :make_clone
        post   :build_all
      end
      get :autocomplete_user_uname, :on => :collection
      resources :repositories do
        member do
          get :add_project
          delete :remove_project
          get :projects_list
        end
      end
      resources :products do
        resources :product_build_lists, :only => [:create, :destroy]
      end
    end
    match '/private/:platform_name/*file_path' => 'privates#show'

    resources :product_build_lists, :only => [:index]
  end

  namespace :admin do
    resources :users do
      get :list, :on => :collection
    end
    resources :register_requests, :only => [:index] do
      put :update, :on => :collection
      member do
        get :approve
        get :reject
      end
    end
    resources :event_logs, :only => :index
  end

  scope :module => 'users' do
    resources :settings, :only => [] do
      collection do
        get :profile
        put :profile
        get :private
        put :private
        get :notifiers
        put :notifiers
      end
    end

    resources :users, :controller => 'profile', :only => [] do
      get :autocomplete_user_uname, :on => :collection
    end
    resources :register_requests, :only => [:new, :create]
  end

  scope :module => 'groups' do
    resources :groups, :controller => 'profile' do
      get :autocomplete_group_uname, :on => :collection
      delete :remove_user, :on => :member
      resources :members, :only => [:index] do
        collection do
          post :add
          post :update
          delete :remove
        end
      end
    end
  end

  scope :module => 'projects' do
    # Core callbacks
    match 'build_lists/publish_build', :to => "build_lists#publish_build"
    match 'build_lists/status_build', :to => "build_lists#status_build"
    match 'build_lists/post_build', :to => "build_lists#post_build"
    match 'build_lists/pre_build', :to => "build_lists#pre_build"
    match 'build_lists/circle_build', :to => "build_lists#circle_build"
    match 'build_lists/new_bbdt', :to => "build_lists#new_bbdt"
    match 'product_status', :to => 'product_build_lists#status_build'

    resources :build_lists, :only => [:index, :show] do
      member do
        put :cancel
        put :publish
        put :reject_publish
      end
      collection { post :search }
    end

    resources :projects, :only => [:index, :new, :create]
  end
  scope ':owner_name' do # Owner
    constraints OwnerConstraint.new(User) do
      get '/' => 'users/profile#show', :as => :user
    end
    constraints OwnerConstraint.new(Group, true) do
      get '/' => 'groups/profile#show', :as => :group_profile
    end
    scope ':project_name', :as => 'project', :module => 'projects' do
      resources :wiki do
        collection do
          match '_history' => 'wiki#wiki_history', :as => :history, :via => :get
          match '_access' => 'wiki#git', :as => :git, :via => :get
          match '_revert/:sha1/:sha2' => 'wiki#revert_wiki', :as => :revert, :via => [:get, :post]
          match '_compare' => 'wiki#compare_wiki', :as => :compare, :via => :post
          #match '_compare/:versions' => 'wiki#compare_wiki', :versions => /.*/, :as => :compare_versions, :via => :get
          match '_compare/:versions' => 'wiki#compare_wiki', :versions => /([a-f0-9\^]{6,40})(\.\.\.[a-f0-9\^]{6,40})/, :as => :compare_versions, :via => :get
          post :preview
          get :search
          get :pages
        end
        member do
          get :history
          get :edit
          match 'revert/:sha1/:sha2' => 'wiki#revert', :as => :revert_page, :via => [:get, :post]
          match ':ref' => 'wiki#show', :as => :versioned, :via => :get

          post :compare
          #match 'compare/*versions' => 'wiki#compare', :as => :compare_versions, :via => :get
          match 'compare/:versions' => 'wiki#compare', :versions => /([a-f0-9\^]{6,40})(\.\.\.[a-f0-9\^]{6,40})/, :as => :compare_versions, :via => :get
        end
      end
      resources :issues, :except => :edit do
        resources :comments, :only => [:edit, :create, :update, :destroy]
        resources :subscribes, :only => [:create, :destroy]
        collection do
          post :create_label
          get :search_collaborators
        end
      end
      post "/labels/:label_id" => "issues#destroy_label", :as => :issues_delete_label
      post "/labels/:label_id/update" => "issues#update_label", :as => :issues_update_label
      resources :build_lists, :only => [:index, :new, :create] do
        collection { post :search }
      end
      resources :collaborators do
        get :find, :on => :collection
      end
      resources :pull_requests, :except => [:destroy, :new] do
        collection do
          post '/new' => 'pull_requests#new'
          get :autocomplete_base_project_name
          get :autocomplete_head_project_name
        end
      end

    end
    scope ':project_name', :module => 'projects' do
      # Resource
      get '/edit' => 'projects#edit', :as => :edit_project
      put '/' => 'projects#update'
      delete '/' => 'projects#destroy'
      # Member
      post '/fork' => 'projects#fork', :as => :fork_project
      get '/sections' => 'projects#sections', :as => :sections_project
      post '/sections' => 'projects#sections'
      delete '/remove_user' => 'projects#remove_user', :as => :remove_user_project
      # Tree
      get '/' => "git/trees#show", :as => :project
      get '/tree/:treeish(/*path)' => "git/trees#show", :defaults => {:treeish => :master}, :as => :tree, :format => false
      # Commits
      get '/commits/:treeish(/*path)' => "git/commits#index", :defaults => {:treeish => :master}, :as => :commits, :format => false
      get '/commit/:id(.:format)' => "git/commits#show", :as => :commit
      # Commit comments
      post '/commit/:commit_id/comments(.:format)' => "comments#create", :as => :project_commit_comments
      get '/commit/:commit_id/comments/:id(.:format)' => "comments#edit", :as => :edit_project_commit_comment
      put '/commit/:commit_id/comments/:id(.:format)' => "comments#update", :as => :project_commit_comment
      delete '/commit/:commit_id/comments/:id(.:format)' => "comments#destroy"
      # Commit subscribes
      post '/commit/:commit_id/subscribe' => "commit_subscribes#create", :as => :subscribe_commit
      delete '/commit/:commit_id/unsubscribe' => "commit_subscribes#destroy", :as => :unsubscribe_commit
      # Editing files
      get '/blob/:treeish/*path/edit' => "git/blobs#edit", :defaults => {:treeish => :master}, :as => :edit_blob
      put '/blob/:treeish/*path' => "git/blobs#update", :defaults => {:treeish => :master}, :format => false
      # Blobs
      get '/blob/:treeish/*path' => "git/blobs#show", :defaults => {:treeish => :master}, :as => :blob, :format => false
      # Blame
      get '/blame/:treeish/*path' => "git/blobs#blame", :defaults => {:treeish => :master}, :as => :blame, :format => false
      # Raw
      get '/raw/:treeish/*path' => "git/blobs#raw", :defaults => {:treeish => :master}, :as => :raw, :format => false
      # Archive
      get '/archive/:format/tree/:treeish' => "git/trees#archive", :defaults => {:treeish => :master}, :as => :archive, :format => /zip|tar/
    end
  end
end
