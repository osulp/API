require 'open-uri'
require 'cgi'

class AlmaSpecialHours
  attr_reader :xml_doc

  def initialize
    @xml_doc = fetch_dates
  end

  def xml_document
    @xml_doc
  end

  private

  ##
  # Fetch the Alma Special Hours xml document for the date specified
  # @return [XML::Document]
  def fetch_dates
    logger = Rails.logger
    begin
      Rails.cache.fetch("#{special_hours_url}/AlmaSpecialHours/fetch", expires_in: cached_for) { open(special_hours_url).read }
    rescue ArgumentError
      logger.error("ArgumentError: invalid request")
      return nil
    rescue StandardError => e
      logger.error("StandardError: #{e.message}")
      return nil
    end
  end

  def special_hours_url
    headers = { CGI::escape('apikey') => apikey, CGI::escape('scope') => special_hours_scope }
    "#{alma_url}?#{headers.to_query}"
  end

  def special_hours_scope
    ENV['ALMA_SPECIAL_HOURS_SCOPE']
  end

  def alma_url
    ENV['ALMA_SPECIAL_HOURS_URL']
  end

  def cached_for
    ENV['ALMA_CACHED_FOR']
  end

  def apikey
    ENV['ALMA_API_KEY']
  end

end
