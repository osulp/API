Rails.application.routes.draw do
  post '/hours', :to => 'api#hours', :as => 'api_hours'
  get '/widgets/:template', :to => 'widgets#show'
end
