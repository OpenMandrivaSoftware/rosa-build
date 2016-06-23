require 'sidekiq/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do

  # ActiveAdmin routes.
  ActiveAdmin.routes(self)

  namespace :admin do
    constraints Rosa::Constraints::AdminAccess do
      mount Sidekiq::Web => 'sidekiq'
    end
  end

  match '/robots.txt' => 'sitemap#robots', via: [:get, :post, :head], as: :robots

  resources :statistics, only: [:index]
  resource :contact, only: [:new, :create, :sended] do
    get '/' => 'contacts#new'
    get :sended
  end

  devise_scope :user do
    get 'users/sign_up' => 'users/registrations#new',    as: :new_user_registration
    post 'users'        => 'users/registrations#create', as: :user_registration
  end

  devise_for :users, controllers: {
    confirmations:      'users/confirmations'
  }, skip: [:registrations]

  namespace :api do
    namespace :v1, constraints: { format: 'json' }, defaults: { format: 'json' } do
      resources :search, only: [:index]
      resources :build_lists, only: [:index, :create, :show] do
        member {
          put :publish
          put :reject_publish
          put :rerun_tests
          put :cancel
          put :create_container
          put :publish_into_testing
        }
      end
      resources :arches, only: :index
      resources :platforms, only: %i(index show update destroy create) do
        collection {
          get :platforms_for_build
          get :allowed
        }
        member {
          get :members
          put :add_member
          delete :remove_member
          post :clone
          put :clear
        }
        resources :maintainers, only: [ :index ]
      end
      resources :repositories, only: [:show, :update, :destroy] do
        member {
          get     :projects
          get     :key_pair
          get     :packages
          put     :add_member
          delete  :remove_member
          put     :add_project
          delete  :remove_project
          put     :signatures
          put     :add_repo_lock_file
          delete  :remove_repo_lock_file
        }
      end
      resources :projects, only: [:index, :show, :update, :create, :destroy] do
        collection { get :get_id }
        member {
          get    :members
          put    :add_member
          delete :remove_member
          put    :update_member
        }
        resources :build_lists, only: :index
      end
      resources :users, only: [:show]
      get 'user' => 'users#show_current_user'
      resource :user, only: [:update] do
        member {
          get :notifiers
          put :notifiers
        }
      end
      resources :groups, only: [:index, :show, :update, :create, :destroy] do
        member {
          get :members
          put :add_member
          delete :remove_member
          put :update_member
        }
      end
      resources :products, only: [:show, :update, :create, :destroy] do
        resources :product_build_lists, only: :index
      end
      resources :product_build_lists, only: [:index, :show, :destroy, :create, :update] do
        put :cancel, on: :member
      end

      resources :jobs do
        collection do
          get :shift
          get :status
          put :feedback
          put :logs
          put :statistics
        end
      end

    end
  end

  resources :search, only: [:index]

  get  '/forbidden'        => 'pages#forbidden',      as: 'forbidden'
  get  '/terms-of-service' => 'pages#tos',            as: 'tos'

  get '/activity.:format'       => 'home#activity',     as: 'activity_feeds', format: /json/
  get '/activity_feeds.:format' => 'home#activity',     as: 'atom_activity_feeds', format: /atom/
  get '/own_activity.:format'   => 'home#own_activity', as: 'own_activity', format: /json/

  if APP_CONFIG['anonymous_access']
    authenticated do
      root to: 'home#index'
    end
    unauthenticated do
      root to: 'statistics#index', as: :unauthenticated_root
      #devise_scope :user do
      #  root to: 'devise/sessions#new', as: :unauthenticated_root
      #end
    end
  else
    root to: 'home#index'
  end

  scope module: 'platforms' do
    resources :platforms, constraints: {id: Platform::NAME_PATTERN} do
      member do
        put    :regenerate_metadata
        put    :clear
        get    :clone
        get    :members
        delete :remove_members
        post   :change_visibility
        post   :add_member
        post   :make_clone
      end

      resources :contents, only: %i(index) do
        collection do
          delete :remove_file
        end
      end

      resources :mass_builds, only: [:create, :new, :index, :show] do
        member do
          post   :cancel
          post   :publish
          get 'show_fail_reason(/:page)' => 'mass_builds#show_fail_reason', as: :show_fail_reason, page: /[0-9]+/, defaults: { page: '1' }
          get '/:kind' => "mass_builds#get_list", as: :get_list, kind: /failed_builds_list|missed_projects_list|projects_list|tests_failed_builds_list|success_builds_list/
        end
      end

      resources :repositories, only: [:create, :new, :show, :edit, :update] do
        member do
          get     :manage_projects
          put     :add_project
          delete  :remove_project
          get     :projects_list
          delete  :remove_members
          post    :add_member
          put     :regenerate_metadata
          put     :sync_lock_file
        end
      end
      resources :key_pairs, only: [:create, :index, :destroy]
      resources :tokens, only: [:create, :index, :show, :new] do
        member do
          post :withdraw
        end
      end
      resources :products do
        resources :product_build_lists, only: [:create, :destroy, :new, :show, :update] do
          member {
            get :log
            put :cancel
          }
        end
        collection { 
          get :autocomplete_project 
          get :project_versions
        }
      end
      resources :maintainers, only: [:index]
    end

    resources :product_build_lists, only: [:index, :show, :update]
  end

  resources :autocompletes, only: [] do
    collection do
      get :autocomplete_user_uname
      get :autocomplete_extra_build_list
      get :autocomplete_extra_mass_build
      get :autocomplete_extra_repositories
      get :autocomplete_user_or_group
    end
  end

  scope module: 'users' do

    resources :settings, only: [] do
      collection do
        get :profile
        patch :profile
        get :private
        patch :private
        get :notifiers
        patch :notifiers
        get :builds_settings
        patch :builds_settings
        put :reset_auth_token
      end
    end

    get '/allowed'  => 'users#allowed'
    get '/check'    => 'users#check'
    get '/discover' => 'users#discover'
  end

  scope module: 'groups' do
    get '/groups/new' => 'profile#new' # need to force next route exclude id: 'new'
    get '/groups/:id' => redirect("/%{id}"),        as: :profile_group # override default group show route
    resources :groups, controller: 'profile' do
      delete :remove_user, on: :member
      resources :members, only: [:index] do
        collection do
          post   :add
          put    :update
          delete :remove
        end
      end
    end
  end

  scope module: 'projects' do
    resources :build_lists, only: [:index, :show] do
      member do
        put :cancel
        put :create_container
        put :rerun_tests
        get :log
        patch :publish
        put :reject_publish
        put :publish_into_testing
        get :dependent_projects
        post :dependent_projects
      end
    end

    resources :projects, only: [:index, :new, :create]

    scope '*name_with_owner', name_with_owner: Project::OWNER_AND_NAME_REGEXP do # project
      scope as: 'project' do
        resources :build_lists, only: [:index, :new, :create]
        put 'schedule' => 'projects#schedule'
      end

      # Resource
      get '/autocomplete_maintainers' => 'projects#autocomplete_maintainers', as: :autocomplete_maintainers
      get '/modify' => 'projects#edit', as: :edit_project
      patch '/' => 'projects#update', as: :project
      delete '/' => 'projects#destroy'

      get '/commit/:sha' => 'projects#commit', as: :commit
      get '/diff/:diff' => 'projects#diff', as: :diff, format: false, diff: /.*/
    end
  end

  scope ':uname' do # project owner profile
    constraints Rosa::Constraints::Owner.new(User) do
      get '/' => 'users/profile#show', as: :user
    end
    constraints Rosa::Constraints::Owner.new(Group, true) do
      get '/' => 'groups/profile#show'
    end
  end

  # As of Rails 3.0.1, using rescue_from in your ApplicationController to
  # recover from a routing error is broken!
  # see: https://rails.lighthouseapp.com/projects/8994/tickets/4444-can-no-longer-rescue_from-actioncontrollerroutingerror
  get '*a', to: 'application#render_404'
end
