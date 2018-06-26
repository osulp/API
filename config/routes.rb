Rails.application.routes.draw do
  post '/hours', :to => 'api#hours', :as => 'api_hours'
  get '/special_hours', :to => 'api#special_hours', :as => 'api_special_hours'
  get '/widgets/hours/:template', :to => 'widgets#hours'
end
