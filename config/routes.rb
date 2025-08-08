# config/routes.rb

Rails.application.routes.draw do
  scope "(:locale)", locale: /vi|en/ do
    root "static_pages#home"

    # --- Authentication & User Management ---
    get "/signup", to: "users#new"
    post "/signup", to: "users#create"
    get "/login", to: "sessions#new"
    post "/login", to: "sessions#create"
    delete "/logout", to: "sessions#destroy"

    resources :account_activations, only: :edit
    resources :password_resets, only: %i(new create edit update)
    resources :users, only: %i(show edit update)

    # Subject search API (accessible to all authenticated users)
    resources :subjects, only: :index

    # --- Trainee Namespace ---
    namespace :trainee do
      resources :daily_reports, only: %i(index show new create edit update destroy)

      resources :courses, only: %i(show) do
        member do
          get :members
          get :subjects
        end
        resources :subjects, only: %i(show)
      end

      resources :user_subjects, only: %i(update)
      resources :user_tasks, only: [] do
        member do
          patch :update_document, path: "document"
          patch :update_status, path: "status"
          patch :update_spent_time, path: "spent_time"
          delete :destroy_document, path: "document"
        end
      end
    end

    # --- Supervisor Namespace ---
    namespace :supervisor do
      resources :daily_reports, only: %i(index show)
      resources :subjects, only: %i(index show destroy new create edit update)
      resources :tasks, only: %i(index show destroy new create edit update)  
      resources :categories, only: %i(index show destroy new create edit update)
      resources :users, only: %i(index show) do
        member do
          patch :update_status
        end
        collection do
          patch :bulk_deactivate
        end
      end
      resources :courses, only: %i(index show new create edit update) do
        member do
          get :members
          get :subjects
          get :supervisors
          delete :leave
          post :add_subject
        end
        resources :user_courses, only: [:destroy]
        resources :supervisors, only: [:destroy]
        resources :course_subjects, only: [:destroy] do
          post :finish, on: :member
        end
      end
    end

    # --- Admin Namespace ---
    namespace :admin do
      resources :dashboards
      resources :daily_reports, only: %i(index show)
    end
  end
end
