Rails.application.routes.draw do
  post '/hours', :to => 'api#hours', :as => 'api_hours'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
