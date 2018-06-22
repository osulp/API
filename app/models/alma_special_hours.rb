require 'open-uri'
require 'cgi'

class AlmaSpecialHours
  def self.fetch(url, apikey, cached_for)

    begin
      headers  = { CGI::escape('apikey') => apikey }
      url = "#{url}?#{headers.to_query}"
      Rails.cache.fetch("#{url}/AlmaSpecialHours/fetch", expires_in: cached_for) { open(url).read }

    rescue ArgumentError
      raise BadRequest.new(), "Invalid request"
    rescue StandardError => e
      raise e
    end
  end
end