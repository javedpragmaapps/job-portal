Rails.application.routes.draw do

  # Module API Routes 
  namespace :api do
    namespace :v1 do

      # Jobs Module API Routes
      resources :jobs, only: [:show, :update, :destroy]
      get 'jobs' => 'jobs#index'
      post '/syncjobs' => 'jobs#syncjobs'
      # get '/jobs:id' => 'jobs#show'
      get '/jobs/companies/list' => 'jobs#companiesList'
      get '/jobs/companies/list/:id' => 'jobs#companiesListById'
      put '/jobs/companies/list/:id' => 'jobs#updateCompanyById'
      post '/jobs/allocatejob/:user_id' => 'jobs#allocateJobsToUsers'

      
      # applicants Module API Routes
      get 'marketplace/applicants' => 'applicants#fetchAllApplicant'
      post 'marketplace/applicants' => 'applicants#saveApplicant'
      put 'marketplace/applicants/:id' => 'applicants#updateApplicant'
      delete 'marketplace/applicants/:id' => 'applicants#deleteApplicantById'
      put 'marketplace/favorite' => 'applicants#markFavoriteJob'
      get 'marketplace/favorite/jobs' => 'applicants#listFavoriteJobs'
      get 'marketplace/referredjobs' => 'applicants#referredjobs'
      get 'marketplace/jobs/categories' => 'applicants#jobCategories'
      
      ## Wallet Module API Routes
      get 'wallet' => 'wallet#getWallet'
      post 'wallet/redeem' => 'wallet#redeemRequest'
      get 'wallet/transactions' => 'wallet#fetchPendingTransactions'
      post 'wallet/transactions/:id' => 'wallet#updateTransaction'

      ## Dashboard Module API Routes
      get 'dashboard/categories' => 'dashboard#fetchCategorisedData'
      get 'dashboard/counts' => 'dashboard#getCountForDashboard'

      # User Role API Routes
      resources :role, only: [:index, :show, :create, :update, :destroy]
      # get 'role' => 'role#fetchListofRoles'
      # get 'role/index'

      # User Module API Routes
      get 'user/all' => 'user#index'
      get 'user/referralCode' => 'user#fetchReferralcode'
      # resources :user, only: [:index, :show, :create, :update, :destroy]
    end
  end


  get '/current_user', to: 'current_user#index'
  devise_for :users, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  },
  controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }


  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
