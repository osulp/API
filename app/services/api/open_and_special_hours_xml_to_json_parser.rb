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
            status: parse_child(day.xpath("status"))
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
      date_range.map.with_index do |day, i|
        # (2) override opening hours if special date (type EXCEPTION) is found
        std_opening_data = lib_opening_hours(json_data, exceptions_data, day)

        # (3) TODO: if multiple opening hours found, return hours in an array as a new
        # field
        json_hours_data[day.to_s] = std_opening_data
      end
      json_hours_data.to_json
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
          info << { type: e.last["type"], status: e.last["status"], desc: e.last["desc"], from_hour: e.last["from_hour"], to_hour: e.last["to_hour"] }
        end
      end
      info
    end

    def self.lib_opening_hours(json_data, exceptions_data, date)
      data = {}
      day_of_week = date.strftime("%A").upcase

      # get std opening hours
      opening_hours = json_data.select {|h,v| v[:day_of_week] == day_of_week && v[:type] == "WEEK"}

      @from_hour = opening_hours.map { |h,v| v[:from_hour]}.first
      @to_hour = opening_hours.map { |h,v| v[:to_hour]}.first
      @event_desc = ""
      @event_status = ""
      @all_exceptions = {}
      @all_hours_raw = {}

      # get special hours and override std opening hours
      exceptions = exceptions_data[date.to_s]
      override_hours(exceptions, date)

      data = {
        open: get_formatted_open_time(@from_hour),
        close: get_formatted_close_time(@to_hour),
        string_date: date.strftime("%a, %b %-d, %Y"),
        sortable_date: date.strftime("%Y-%m-%d"),
        formatted_hours: formatted_hours(@from_hour, @to_hour),
        open_all_day: open_all_day?(@from_hour, @to_hour),
        closes_at_night: closes_at_night?(@to_hour, date),
        event_desc: @event_desc.present? ? @event_desc : "",
        event_status: @event_status.present? ? @event_status : "",
        # all_exceptions: @all_exceptions.present? ? @all_exceptions : ""
      }
      data
    end

    def self.override_hours(exceptions, date)
      week_from = @from_hour
      week_to = @to_hour
      if exceptions.present?
        exceptions.each_with_index do |e, index|
          if index == 0
            # first exception
            first_exception = e

            # if closed all day for date, then override from_hour and to_hour
            if closed_all_day?(first_exception)
              @from_hour = ''
              @to_hour = ''
              @event_desc = first_exception[:desc]
              @event_status = first_exception[:status]
            elsif (Time.parse(@from_hour) < Time.parse(first_exception[:from_hour])) && (@to_hour == first_exception[:to_hour])
              # partially closed, we close early
              @to_hour = (Time.parse(first_exception[:from_hour])).strftime("%H:%M")
            elsif (Time.parse(@to_hour) > Time.parse(first_exception[:to_hour])) && (@from_hour == first_exception[:from_hour])
              # partially closed, we open late
              @from_hour = (Time.parse(first_exception[:to_hour])).strftime("%H:%M")
            elsif first_exception[:status] == "OPEN" && first_exception[:from_hour] == "00:00"
              @from_hour = first_exception[:from_hour]
              @to_hour = first_exception[:to_hour]
              @event_desc = ""
              @event_status = ""
            end

          else
            # partially closed, but we have multiple from/to pairs

            if exceptions[index-1].present? && exceptions[index].present?
              prev_pair = exceptions[index-1]
              # the next exception is also close, so we should calculate the
              # open pair in between assuming regular week hours are also open

              if e[:status] == "CLOSE" && prev_pair[:status] == "CLOSE" && Time.parse(e[:from_hour]) > Time.parse(prev_pair[:to_hour])
                tmp_from = Time.parse(prev_pair[:to_hour])+1.minute
                tmp_to = Time.parse(e[:from_hour])-1.minute
                if (Time.parse(week_from)..Time.parse(week_to)).include?(tmp_from..tmp_to)
                  @all_hours_raw[tmp_from] = {
                    from_hour: (tmp_from).strftime("%H:%M"),
                    to_hour: (tmp_to).strftime("%H:%M"),
                    status: "OPEN"
                  }
                end
              end
            end
          end
          @all_hours_raw[Time.parse(e[:from_hour])] = { from_hour: e[:from_hour], to_hour: e[:to_hour], status: e[:status], desc: e[:desc]}
          # add all available exceptions to the @all_exceptions hash
          @all_exceptions[Time.parse(e[:from_hour])] = e
        end
        # byebug if date == DateTime.parse("2018-12-10")
      end
    end

    def self.exception_hours(json_data)
      json_data.select { |h,v| exception_close?(v) || exception_open?(v) }.to_json
    end

    def self.exception_close?(item)
      item[:type] == "EXCEPTION" && item[:status] == "CLOSE"
    end

    def self.exception_open?(item)
      item[:type] == "EXCEPTION" && item[:status] == "OPEN"
    end

    def self.get_event_desc(hours, date, exceptions_data)
      exception = exceptions_data[date.to_s]
      event_desc = exception.present? && closed_all_day?(exception.first) ? exception.first[:desc] : ""

      event_desc.present? ? event_desc : ""
    end

    def self.get_event_status(hours, date, exceptions_data)
      exception = exceptions_data[date.to_s]
      event_status = exception.present? && closed_all_day?(exception.first) ? exception.first[:status] : ""

      event_status.present? ? event_status : ""
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

    def self.closes_at_night?(close_time, date)
      exceptions = @all_exceptions.sort
      first_exception = exceptions.first.present? ? exceptions.first : []
      last_exception = exceptions.last.present? ? exceptions.last : []

      if first_exception.second.present? && last_exception.second.present? && first_exception.second[:from_hour] == "00:00" && last_exception.second[:status] == "OPEN"
        ['00:14','23:59','00:59'].include?(last_exception.second[:to_hour]) ? false : true
      else
        ['00:14','23:59','00:59'].include?(close_time) ? false : true
      end
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
