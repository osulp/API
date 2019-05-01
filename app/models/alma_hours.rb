# frozen_string_literal: true

require 'open-uri'

# Fetch Alma Open Hours given a full alma_url
# @param [String] alma_url i.e "https://alma-base-url/open-hours?apikey=abc123etc&from=2019-06-24&to=2019-06-24"
# @return [String] raw JSON string from alma (return nil on error)
#
# Input alma_url = "https://alma-base-url/open-hours?apikey=abc123etc&from=2019-06-24&to=2019-06-24"
# Output:
# "{\"day\":[{\"date\":\"2019-06-24Z\",\"day_of_week\":{\"value\":\"2\",\"desc\":\"Monday\"},\"hour\":[{\"from\":\"07:30\",\"to\":\"21:00\"}]}]}"
class AlmaHours
  def self.fetch(alma_url)
    logger = Rails.logger
    begin
      Rails.cache.fetch(cache_key(alma_url), expires_in: cached_for) do
        URI.open(alma_url, headers).read
      end
    rescue StandardError => e
      logger.error("StandardError: #{e.message} : #{e.backtrace}")
      return nil
    end
  end

  def self.cached_for
    ENV['ALMA_CACHED_FOR']
  end

  def self.cache_key(alma_url)
    "#{alma_url}/AlmaOpenHours/fetch"
  end

  def self.headers
    { 'Accept' => 'application/json' }
  end
end
