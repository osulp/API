require 'open-uri'
require 'cgi'

class AlmaHours
  def self.fetch(date_from, date_to, url, apikey, cached_for)

    begin
      headers  = { CGI::escape('from') => date_from, CGI::escape('to') => date_to, CGI::escape('apikey') => apikey }
      url = "#{url}?#{headers.to_query}"
      Rails.cache.fetch("#{date_from}#{date_to}#{url}/AlmaOpenHours/fetch", expires_in: cached_for) { open(url).read }

    rescue ArgumentError
      raise BadRequest.new(), "Invalid date requested, must use format YYYY-MM-dd"
    rescue StandardError => e
      raise e
    end
  end
end
