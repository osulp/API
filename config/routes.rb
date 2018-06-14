Rails.application.routes.draw do
  get '/hours', :to => 'hours#index', :as => 'hours_index'
end
