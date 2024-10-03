resources :users, only: [:show] do
  member do
    get :upload_id_card
    patch :submit_id_card
  end
  resources :direct_messages, only: [:new, :create, :show]
end
