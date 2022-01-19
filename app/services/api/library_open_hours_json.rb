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
    def self.call(raw_hours, limited = false)
      new(raw_hours, limited).call
    end

    def call
      hours_data = {}
      @raw_hours.each do |day, hour|
        hours_data[day] = lib_open_hours(hour['day'])
      end
      hours_data.to_json
    end

    private

    def initialize(raw_hours, limited = false)
      @raw_hours = raw_hours
      @limited = limited
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
        formatted_hours: all_formatted_hours(alma_day, false),
        formatted_hours_plain_text: all_formatted_hours(alma_day, true),
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

    def all_close_hours(day)
      close = []
      day['hour'].each_with_index do |h, i|
        close << { from: h['to'], to: day['hour'][i + 1]['from'] } if i < (day['hour'].count - 1)
      end
      close
    end

    def event_status(day)
      all_open_hours(day).count.zero? ? 'CLOSE' : ''
    end

    def all_formatted_hours(day, plain_text = false)
      return 'Closed' if all_open_hours(day).count.zero?

      return limited_formatted_hours(day, plain_text) if limited_hours?(day)

      all_open_hours(day).map do |h|
        formatted_hours(h[:open], h[:close])
      end.join(hours_delimiter(plain_text))
    end

    def hours_delimiter(plain_text = false)
      plain_text == true ? ', ' : '<br>'
    end

    def limited_formatted_hours(day, plain_text)
      hour = day['hour']
      if hour.first['from'] == '00:00' && hour.last['to'] == '23:59'
        limited_hours_open_24_hours(plain_text)
      else
        limited_hours_not_open_24_hours(hour, plain_text)
      end
    end

    def limited_hours_open_24_hours(plain_text)
      "#{I18n.translate(:limited_hours_open_24_hours)}#{limited_hours_info(plain_text)}"
    end

    def limited_hours_not_open_24_hours(hour, plain_text)
      "#{I18n.translate(:limited_hours_not_open_24_hours,
                        from: format_hour(hour.first['from']),
                        to: format_hour(hour.last['to']))}#{limited_hours_info(plain_text)}"
    end

    def limited_hours_info(plain_text = false)
      return "#{hours_delimiter(plain_text)}#{I18n.translate(:limited_hours_info_plain)}" if plain_text == true

      "#{hours_delimiter(plain_text)}#{I18n.translate(:limited_hours_info_html)}"
    end

    def limited_hours?(day)
      # byebug if day['date'] == '2020-01-07Z'
      all_close_hours(day).include?(from: '02:00', to: '06:00') && @limited == true
    end

    def partially_open?(open_time, close_time)
      open_time != '00:00' && close_time == '23:59' ? true : false
    end

    def open_all_day?(open_time, close_time)
      open_time == '00:00' && close_time == '23:59' ? true : false
    end

    def formatted_hours(open_time, close_time)
      if close_time == '00:14' || partially_open?(open_time, close_time)
        "#{format_hour(open_time)} - Midnight"
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
