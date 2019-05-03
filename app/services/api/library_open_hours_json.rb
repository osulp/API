# frozen_string_literal: true

# This returns a json object that contains open hours
# Input: Raw JSON from Alma
# output: OSULP JSON with additional fields
module API
  # Format raw json hours fetched from Alma and return the expected format ready
  # to be rendered.
  #
  # @param [Hash] raw_hours
  # @returns [String] hours in json format
  class LibraryOpenHoursJson
    def self.call(raw_hours)
      new(raw_hours).call
    end

    def call
      hours_data = {}
      @raw_hours.each do |day, hour|
        hours_data[day] = lib_open_hours(hour['day'])
      end
      hours_data.to_json
    end

    private

    def initialize(raw_hours)
      @raw_hours = raw_hours
    end

    def lib_open_hours(raw_json)
      return {} if raw_json.blank?

      alma_day = raw_json.first
      from_hour = alma_from_hour(alma_day)
      to_hour = alma_to_hour(alma_day)
      last_to_hour = alma_last_to_hour(alma_day)
      alma_date = alma_date_time(alma_day)
      data = {
        open: from_hour.present? ? format_hour(from_hour) : '',
        close: to_hour.present? ? format_hour(to_hour) : '',
        string_date: alma_date.strftime('%a, %b %-d, %Y'),
        sortable_date: alma_date.strftime('%Y-%m-%d'),
        formatted_hours: all_formatted_hours(alma_day),
        open_all_day: open_all_day?(from_hour, to_hour),
        closes_at_night: closes_at_night?(last_to_hour),
        event_desc: '',
        event_status: event_status(alma_day),
        all_open_hours: all_open_hours(alma_day)
      }
      data
    end

    def alma_date_time(alma_day)
      DateTime.parse(alma_day['date'])
    end

    def alma_from_hour(alma_day)
      alma_day['hour'].first['from'] if alma_day['hour'].present?
    end

    def alma_to_hour(alma_day)
      alma_day['hour'].first['to'] if alma_day['hour'].present?
    end

    def alma_last_to_hour(alma_day)
      alma_day['hour'].last['to'] if alma_day['hour'].present?
    end

    def closes_at_night?(close_time)
      ['00:14', '23:59', '00:59'].include?(close_time) ? false : true
    end

    def all_open_hours(day)
      day['hour'].map { |h| { open: h['from'], close: h['to'] } }
    end

    def event_status(day)
      all_open_hours(day).count.zero? ? 'CLOSE' : ''
    end

    def all_formatted_hours(day)
      return 'Closed' if all_open_hours(day).count.zero?

      all_open_hours(day).map do |h|
        formatted_hours(h[:open], h[:close])
      end.join(', ')
    end

    def partially_open?(open_time, close_time)
      open_time != '00:00' && close_time == '23:59' ? true : false
    end

    def open_all_day?(open_time, close_time)
      open_time == '00:00' && close_time == '23:59' ? true : false
    end

    def formatted_hours(open_time, close_time)
      if close_time == '00:14' || partially_open?(open_time, close_time)
        "#{format_hour(open_time)} - No Closing"
      elsif open_time == '00:14'
        "Closes at #{format_hour(close_time)}"
      elsif open_time == '00:00' && close_time == '23:59'
        'Open 24 Hours'
      elsif open_time.eql? close_time
        'Closed'
      else
        "#{format_hour(open_time)} - #{format_hour(close_time)}"
      end
    end

    def format_hour(time)
      Time.parse(time).strftime('%-l:%M%P')
    end
  end
end
