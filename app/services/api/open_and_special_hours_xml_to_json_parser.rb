#This returns a json object that contains open and special dates info
#Input: XML from alma special hours
#output: JSON for every day with event info and closures
module API
  class OpenAndSpecialHoursXmlToJsonParser
    def self.call(hours_xml, dates)
      parse_xml(hours_xml, dates)
    end

    private

    def self.parse_xml(hours_xml, dates)
      json_data = {}
      parsed_xml = xml_parser.parse(hours_xml)
      all_hours_list = parsed_xml.xpath("//open_hour")
      all_hours_list.each_with_index do |day, i|
        data = {
            type: parse_child(day.xpath("type")),
            desc: parse_child(day.xpath("desc")),
            from_date: parse_child(day.xpath("from_date")),
            to_date: parse_child(day.xpath("to_date")),
            from_hour: parse_child(day.xpath("from_hour")),
            to_hour: parse_child(day.xpath("to_hour")),
            day_of_week: parse_child(day.xpath("day_of_week")),
            status: parse_child(day.xpath("status")),
            formatted_hours: get_formatted_hours(day),
            formatted_dates: get_formatted_dates(day)
        }
        json_data[i.to_s] = data
      end
      open_and_special_hours(json_data, dates)
    end

    def self.open_and_special_hours(json_data, dates)
      json_hours_data = {}

      exceptions_data = get_special_info_list(dates, json_data)

      # (1) for each day in dates get standard opening hours (type WEEK)
      date_range = DateTime.parse(dates.first)..DateTime.parse(dates.last)
      week_days = date_range.map.with_index do |day, i|
        # (2) override opening hours if special date (type EXCEPTION) is found
        std_opening_data = std_opening_hours(json_data, exceptions_data, day)

        # (3) TODO: if multiple opening hours found, return hours in an array as a new
        # field
        json_hours_data[day.to_s] = std_opening_data
      end
      json_hours_data
    end

    def self.get_special_info_list(dates, json_data)
      Hash[(DateTime.parse(dates.first)..DateTime.parse(dates.last)).map do |d|
        [d.to_s, get_special_info(d, json_data)]
      end]
    end

    def self.get_special_info(day, json_data)
      info = []
      special_events = exception_hours(json_data)
      JSON.parse(special_events).each do |e|
        if e.last["from_date"].present? && e.last["to_date"].present?
          date_range = DateTime.parse(e.last["from_date"])..DateTime.parse(e.last["to_date"])
        elsif e.last["from_date"].present? && e.last["to_date"].blank?
          date_range = DateTime.parse(e.last["from_date"])
        elsif  e.last["from_date"].blank? && e.last["to_date"].present?
          date_range = DateTime.parse(e.last["to_date"])
        else
          date_range = DateTime.parse(e.last["from_date"])
        end
        if date_range === day.beginning_of_day
          info << { status: e.last["status"], desc: e.last["desc"] }
        end
      end
      info
    end

    def self.std_opening_hours(json_data, exceptions_data, date)
      data = {}
      day_of_week = date.strftime("%A").upcase
      opening_hours = json_data.select {|h,v| v[:day_of_week] == day_of_week && v[:type] == "WEEK"}

      if opening_hours.present? && opening_hours.count == 1
        from_hour = opening_hours.map { |h,v| v[:from_hour]}.first
        to_hour = opening_hours.map { |h,v| v[:to_hour]}.first

        data = {
          open: get_formatted_open_time(from_hour),
          close: get_formatted_close_time(to_hour),
          string_date: date.strftime("%a, %b %e, %Y"),
          sortable_date: date.strftime("%Y-%m-%d"),
          formatted_hours: formatted_hours(from_hour, to_hour),
          open_all_day: open_all_day?(from_hour, to_hour),
          closes_at_night: closes_at_night?(to_hour),
          event_desc: get_event_desc(opening_hours, date, exceptions_data),
          event_status: get_event_status(opening_hours, date, exceptions_data)
        }
      end
      data
    end

    def self.exception_hours(json_data)
      json_data.select { |h,v| closed_all_day?(v) }.to_json
    end

    def self.get_event_desc(hours, date, exceptions_data)
      desc = hours.map { |h,v| v[:desc]}.first
      type = hours.map { |h,v| v[:type]}.first

      data = exceptions_data[date.to_s]
      event_desc = data.present? ? data.first[:desc] : desc

      event_desc.present? && type.present? ? event_desc : ""
    end

    def self.get_event_status(hours, date, exceptions_data)
      status = hours.map { |h,v| v[:status]}.first
      data = exceptions_data[date.to_s]
      event_status = data.present? ? data.first[:status] : status

      event_status.present? && status.present? ? event_status : ""
    end

    def self.get_formatted_open_time(from_hour)
      from_hour.present? ? Time.parse(from_hour).strftime("%l:%M%P") : ""
    end

    def self.get_formatted_close_time(to_hour)
      to_hour.present? ? Time.parse(to_hour).strftime("%l:%M%P") : ""
    end

    def self.formatted_hours(open_time, close_time)
      if (close_time == "00:14")
        "#{Time.parse(open_time).strftime("%l:%M%P")} - No Closing"
      elsif (open_time == "00:14")
        "Closes at #{close_time}"
      elsif (open_time == "00:00" && close_time == "23:59")
        "Open 24 Hours"
      elsif (open_time.eql? close_time)
        "Closed"
      else
        "#{Time.parse(open_time).strftime("%l:%M%P")} -#{Time.parse(close_time).strftime("%l:%M%P")}"
      end
    end

    def self.open_all_day?(open_time, close_time)
      (open_time == "00:00" && close_time == "23:59") ? true : false
    end

    def self.closes_at_night?(close_time)
      ['00:14','23:59','00:59'].include?(close_time) ? false : true
    end

    def self.closed_all_day?(record)
      record[:type] == "EXCEPTION" && record[:status] == "CLOSE" && record[:from_hour] == "00:00" && record[:to_hour] == "23:59"
    end

    def self.get_formatted_dates(day)
      from_date = parse_child(day.xpath("from_date"))
      to_date = parse_child(day.xpath("to_date"))

      if from_date.present? && to_date.present? && from_date != to_date
        from_date_str = DateTime.parse(from_date.to_s).strftime("%m/%d/%Y")
        to_date_str = DateTime.parse(to_date.to_s).strftime("%m/%d/%Y")
        "#{from_date_str} - #{to_date_str}"
      elsif from_date.present? && to_date.present? && from_date == to_date
        DateTime.parse(from_date.to_s).strftime("%m/%d/%Y")
      elsif from_date.present? && to_date.blank?
        DateTime.parse(from_date.to_s).strftime("%m/%d/%Y")
      else
       from_date
      end
    end

    def self.get_formatted_hours(day)
      status = parse_child(day.xpath("status"))
      from_hour = parse_child(day.xpath("from_hour"))
      to_hour = parse_child(day.xpath("to_hour"))

      if status == "CLOSE"
        "Closed"
      elsif status == "OPEN" && from_hour.present? && to_hour.present?
        "#{from_hour} - #{to_hour}"
      elsif status == "OPEN"
        "Open"
      else
       status
      end
    end

    def self.parse_child(xml)
     xml.present? ? xml.text : ""
    end

    def self.xml_parser
      Nokogiri::XML
    end
  end
end
