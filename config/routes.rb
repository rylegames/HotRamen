Rails.application.routes.draw do
  get 'events/new'

  get 'attendances/new'

  get 'users/new'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'application#hello'
  #mount Facebook::Messenger::Server, at: 'bot'
  mount Messenger::Bot::Space => "/webhook"
end
