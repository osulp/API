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
    begin
      Rails.cache.fetch("#{special_hours_url}/AlmaSpecialHours/fetch", expires_in: cached_for) { open(special_hours_url).read }

    rescue ArgumentError
      raise BadRequest.new(), "Invalid request"
    rescue StandardError => e
      raise e
    end
  end

  def special_hours_url
    headers = { CGI::escape('apikey') => apikey }
    "#{alma_url}?#{headers.to_query}"
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
