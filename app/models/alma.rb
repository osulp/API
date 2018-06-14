require 'nokogiri'

class Alma
  attr_reader :xml_doc

  def initialize(date_from, date_to)
    @xml_doc = fetch_date(date_from, date_to)
  end

  def open_hours
    {
        days: days(@xml_doc)
        # days: @xml_doc.to_s
    }
  end

  private

  def fetch(*args)
    AlmaOpenHours.fetch(*args)
  end

  ##
  # Build a list of days from the xml doc
  # @param [Nokogiri::XML::Document] xml_doc - the xml doc
  # @return [Array<ClassroomEvent>] an array of ClassroomEvent objects
  def days(xml_doc)
    items = xml_doc.xpath("days")
    return [] if items.empty?
    items.map { |i| AlmaOpenHoursDay.new(i.xpath("day")) }
  end

  ##
  # Fetch the Alma Open Hours xml document for the date specified
  # @param [String] date_from - the date from formatted in YYYY-MM-DD
  # @param [String] date_to - the date to formatted in YYYY-MM-DD
  # @return [Nokogiri::XML::Document]
  def fetch_date(date_from, date_to)
    url = ENV['ALMA_OPEN_HOURS_URL']
    cached_for = ENV['ALMA_CACHED_FOR']
    apikey = ENV['ALMA_API_KEY']
    date_from = '2018-06-14' if date_from.nil?
    date_to = '2018-06-14' if date_to.nil?

    Nokogiri::XML(fetch(date_from, date_to, url, apikey, cached_for))
  end

end
