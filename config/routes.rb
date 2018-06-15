Rails.application.routes.draw do
  get "/hours(/:dates)", to: "Api#hours", as: "hours"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
