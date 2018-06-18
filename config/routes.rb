Rails.application.routes.draw do
  post '/hours', :to => 'api#hours', :as => 'api_hours'
end
