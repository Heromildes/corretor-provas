Rails.application.routes.draw do
  # Só entrar/sair: sem cadastro, sem recuperação de senha.
  devise_for :users, only: :sessions, path: "", path_names: { sign_in: "entrar", sign_out: "sair" },
                     controllers: { sessions: "users/sessions" }
  root "batches#index"

  resources :batches, path: "turmas" do
    resources :submissions, only: :create, path: "provas"
  end

  resources :submissions, only: %i[show update destroy], path: "provas" do
    member { post :regrade }
    resources :items, only: :update, controller: "submission_items", path: "itens"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
