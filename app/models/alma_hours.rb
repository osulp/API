require 'open-uri'
require 'cgi'

class AlmaHours
  def self.fetch(date_from, date_to, url, apikey, cached_for)
    logger = Rails.logger
    begin
      headers  = { CGI::escape('from') => date_from, CGI::escape('to') => date_to, CGI::escape('apikey') => apikey }
      url = "#{url}?#{headers.to_query}"

      Rails.cache.fetch("#{date_from}#{date_to}#{url}/AlmaOpenHours/fetch", expires_in: cached_for) { open(url).read }
    rescue ArgumentError
      logger.error("ArgumentError: invalid date requested, must use format YYYY-MM-dd")
      return nil
    rescue StandardError => e
      logger.error("StandardError: #{e.message}")
      return nil
    end
  end
end
