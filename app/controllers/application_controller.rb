class ApplicationController < ActionController::API

  if %w[production staging development].include? Rails.env
    def append_info_to_payload(payload)
      super(payload)
      Rack::Honeycomb.add_field(request.env, 'classname', self.class.name)
    end
  end
end
