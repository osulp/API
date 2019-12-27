Rails.application.routes.draw do
  post '/hours', :to => 'api#hours', :as => 'api_hours'
  post '/hours/limited', :to => 'api#hours_limited', :as => 'api_hours_limited'
  get '/special_hours', :to => 'api#special_hours', :as => 'api_special_hours'
  get '/widgets/hours/:template', :to => 'widgets#hours'
  get '/widgets/hours/:template/limited', :to => 'widgets#hours_limited'
end
