class Alma
  attr_reader :xml_doc
  attr_reader :xml_special_hours

  def initialize(date_from, date_to)
    @xml_doc = fetch_dates(date_from, date_to)
    @xml_special_hours = fetch_special_dates
  end

  def xml_document
    @xml_doc
  end

  def xml_document_special
    @xml_special_hours
  end

  private

  def fetch_open_hours(*args)
    AlmaHours.fetch(*args)
  end

  def fetch_special_hours(*args)
    AlmaSpecialHours.fetch(*args)
  end

  ##
  # Fetch the Alma Open Hours xml document for the date specified
  # @param [String] date_from - the date from formatted in YYYY-MM-DD
  # @param [String] date_to - the date to formatted in YYYY-MM-DD
  # @return [XML::Document]
  def fetch_dates(date_from, date_to)
    fetch_open_hours(date_from, date_to, alma_open_hours_url, apikey, cached_for)
  end

  ##
  # Fetch Alma Special Hours xml document
  # @return [XML::Document]
  def fetch_special_dates
    fetch_special_hours(alma_special_hours_url, apikey, cached_for)
  end

  def alma_open_hours_url
    ENV['ALMA_OPEN_HOURS_URL']
  end

  def alma_special_hours_url
    ENV['ALMA_SPECIAL_HOURS_URL']
  end

  def cached_for
    ENV['ALMA_CACHED_FOR']
  end

  def apikey
    ENV['ALMA_API_KEY']
  end

end
