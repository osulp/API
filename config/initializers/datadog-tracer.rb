if %w[production staging].include? Rails.env
  Datadog.configure do |c|
    c.use :rails, service_name: "osulp-api-#{Rails.env}"
    c.use :http, service_name: "osulp-api-#{Rails.env}-http"
  end
end
