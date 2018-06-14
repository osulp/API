Rails.application.routes.draw do
  get "/hours", to: "Api#hours", as: "hours"
  get "/hours(/:day)", to: "Api#hours", as: "hours_for_day"
  get "/multi_day_hours/:beginning_day/:end_day", to: "Api#multi_day_hours", as: "hours_for_day"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
