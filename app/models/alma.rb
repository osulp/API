class Alma
  attr_reader :xml_doc

  def initialize(date_from, date_to)
    @xml_doc = fetch_dates(date_from, date_to)
  end

  def xml_document
    @xml_doc
  end

  private

  def fetch(*args)
    AlmaHours.fetch(*args)
  end

  ##
  # Fetch the Alma Open Hours xml document for the date specified
  # @param [String] date_from - the date from formatted in YYYY-MM-DD
  # @param [String] date_to - the date to formatted in YYYY-MM-DD
  # @return [XML::Document]
  def fetch_dates(date_from, date_to)
    fetch(date_from, date_to, alma_url, apikey, cached_for)
  end

  def alma_url
    ENV['ALMA_OPEN_HOURS_URL']
  end

  def cached_for
    ENV['ALMA_CACHED_FOR']
  end

  def apikey
    ENV['ALMA_API_KEY']
  end

end
