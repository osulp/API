# frozen_string_literal: true

require 'cgi'

# Fetch the Alma Open Hours given a date range
class Alma
  attr_reader :raw_hours
  attr_reader :date_from
  attr_reader :date_to

  def initialize(args)
    @date_from = args[:date_from]
    @date_to = args[:date_to]
    @limited = args[:limited]
    @raw_hours = fetch_dates
  end

  def hours_json
    API::LibraryOpenHoursJson.call(@raw_hours, @limited) if @raw_hours.present?
  end

  private

  ##
  # Fetch the Alma Open Hours in json format for the givend dates
  # @return [Hash] raw hours from Alma
  #
  # Example:
  #
  # Input @date_from = '2019-06-24' and @date_to = '2019-06-24'
  # Hash output:
  # {"2019-06-24T00:00:00+00:00"=>{"day"=>[{"date"=>"2019-06-24Z", "day_of_week"=>{"value"=>"2", "desc"=>"Monday"}, "hour"=>[{"from"=>"07:30", "to"=>"21:00"}]}]}}
  def fetch_dates
    return {} if @date_from.blank? || @date_to.blank?

    json_hours_data = {}
    date_range = DateTime.parse(@date_from)..DateTime.parse(@date_to)
    date_range.map do |day|
      date = day.strftime('%Y-%m-%d')
      raw_data = fetch(date, date)
      json_hours_data[day.to_s] = JSON.parse(raw_data) if raw_data.present?
    end
    json_hours_data
  end

  # Fetch Alma Open Hours given date range and full alma url
  #
  # Example:
  #
  # Input args = ["2019-06-24", "2019-06-24"]
  # Output JSON string
  def fetch(*args)
    AlmaHours.fetch(alma_url(*args))
  end

  def alma_param(date_start, date_end)
    {
      CGI.escape('from') => date_start,
      CGI.escape('to') => date_end,
      CGI.escape('apikey') => apikey
    }
  end

  def alma_url(date_start, date_end)
    "#{alma_base_url}?#{alma_param(date_start, date_end).to_query}"
  end

  def alma_base_url
    ENV['ALMA_OPEN_HOURS_URL']
  end

  def apikey
    ENV['ALMA_API_KEY']
  end
end
