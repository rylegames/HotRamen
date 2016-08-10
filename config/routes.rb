Rails.application.routes.draw do
  
  get 'privacy' => 'static_pages#privacy'


  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'application#hello'
  mount Facebook::Messenger::Server, at: 'bot'
end
