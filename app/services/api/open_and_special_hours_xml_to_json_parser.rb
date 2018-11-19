#This returns a json object that contains open and special dates info
#Input: XML from alma special hours
#output: JSON for every day with event info and closures
module API
  class OpenAndSpecialHoursXmlToJsonParser
    def self.call(hours_xml, dates)
      new(hours_xml, dates).call
    end

    def call
      parse_xml
      parse_open_and_special_hours
    end

    private

    def initialize(hours_xml, dates)
      @hours_xml = hours_xml
      @dates = dates
      @raw_json_data = {}
      @exceptions_data = {}
    end

    private

    def parse_xml
      parsed_xml = xml_parser.parse(@hours_xml)
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
        @raw_json_data[i.to_s] = data
      end
      @exceptions_data = exceptions_data
    end

    def exceptions_data
      Hash[(DateTime.parse(@dates.first)..DateTime.parse(@dates.last)).map do |d|
        [d.to_s, get_special_info(d, @raw_json_data)]
      end]
    end

    def get_special_info(day, json_data)
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

    def parse_open_and_special_hours
      json_hours_data = {}
      # for each day in dates get standard opening hours (type WEEK) and
      # override if exceptions are found
      date_range = DateTime.parse(@dates.first)..DateTime.parse(@dates.last)
      date_range.map.with_index do |day, i|
        json_hours_data[day.to_s] = lib_opening_hours(day)
      end
      json_hours_data.to_json
    end

    def lib_opening_hours(date)
      output_data = {}

      # get std opening hours first
      @from_hour = std_opening_hours(date).map { |h,v| v[:from_hour]}.first
      @to_hour = std_opening_hours(date).map { |h,v| v[:to_hour]}.first
      @event_desc = ""
      @event_status = ""
      @all_exceptions = {}
      @open_hours_and_exceptions_override = {}

      override_hours(date)

      # byebug if date == DateTime.parse("2018-12-01")
      output_data = {
        open: get_formatted_open_time(@from_hour),
        close: get_formatted_close_time(@to_hour),
        string_date: date.strftime("%a, %b %-d, %Y"),
        sortable_date: date.strftime("%Y-%m-%d"),
        formatted_hours: all_formatted_hours,
        open_all_day: open_all_day?(@from_hour, @to_hour),
        closes_at_night: closes_at_night?(@to_hour, date),
        event_desc: @event_desc.present? ? @event_desc : "",
        event_status: @event_status.present? ? @event_status : "",
        # all_exceptions: @all_exceptions.present? ? @all_exceptions : ""
      }
      output_data
    end

    def std_opening_hours(date)
      day_of_week = date.strftime("%A").upcase
      @raw_json_data.select {|h,v| v[:day_of_week] == day_of_week && v[:type] == "WEEK"}
    end

    def override_hours(date)
      exceptions = @exceptions_data[date.to_s]
      return if exceptions.blank?

      week_from = @from_hour
      week_to = @to_hour

      exceptions.each_with_index do |e, index|
        if index == 0
          override_from_first_exception(e)
        else
          # partially closed, but we have multiple from/to pairs

          if exceptions[index-1].present? && exceptions[index].present?
            prev_pair = exceptions[index-1]
            # the next exception is also close, so we should calculate the
            # open pair in between assuming regular week hours are also open
            if e[:status] == "CLOSE" && prev_pair[:status] == "CLOSE" && Time.parse(e[:from_hour]) > Time.parse(prev_pair[:to_hour])
              override_build_open_exception({
                tmp_from: Time.parse(prev_pair[:to_hour]), 
                tmp_to: Time.parse(e[:from_hour]), 
                week_from: week_from, 
                week_to: week_to
              })
            end
          end
        end
        @open_hours_and_exceptions_override[Time.parse(e[:from_hour])] = { from_hour: e[:from_hour], to_hour: e[:to_hour], status: e[:status], desc: e[:desc]}
        # add all available exceptions to the @all_exceptions hash
        @all_exceptions[Time.parse(e[:from_hour])] = e
      end
      # byebug if date == DateTime.parse("2018-12-10")
      override_from_additional_exceptions
    end

    def override_from_first_exception(first_exception)
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

    end

    def override_build_open_exception(args)
      if (Time.parse(args[:week_from])..Time.parse(args[:week_to])).include?(args[:tmp_from]..args[:tmp_to])
        @open_hours_and_exceptions_override[args[:tmp_from]] = {
          from_hour: (args[:tmp_from]).strftime("%H:%M"),
          to_hour: (args[:tmp_to]).strftime("%H:%M"),
          status: "OPEN"
        }
      end
    end

    def override_from_additional_exceptions
      tmp_exceptions = @open_hours_and_exceptions_override.sort
      first_ex = tmp_exceptions.first
      last_ex = tmp_exceptions.last

      # since we have multiple exceptions, we take the first OPEN in the list
      # assuming the time is also open in the list

      if first_ex.second[:from_hour] == "00:00" && last_ex.second[:to_hour] == "23:59"
        all_open = @open_hours_and_exceptions_override.select {|h,v| v[:status] == "OPEN"}
        if all_open.count > 0
          # we take the first open available for the main open/close entry
          @from_hour = all_open.first.second[:from_hour]
          @to_hour = all_open.first.second[:to_hour]
          # @event_status = all_open.first.second[:status]
        end
      end
    end

    def exception_hours(json_data)
      json_data.select { |h,v| exception_close?(v) || exception_open?(v) }.to_json
    end

    def exception_close?(item)
      item[:type] == "EXCEPTION" && item[:status] == "CLOSE"
    end

    def exception_open?(item)
      item[:type] == "EXCEPTION" && item[:status] == "OPEN"
    end

    def get_formatted_open_time(from_hour)
      from_hour.present? ? Time.parse(from_hour).strftime("%l:%M%P") : ""
    end

    def get_formatted_close_time(to_hour)
      to_hour.present? ? Time.parse(to_hour).strftime("%l:%M%P") : ""
    end

    def all_formatted_hours
      all_open_exceptions = @open_hours_and_exceptions_override.select {|h,v| v[:status] == "OPEN" }
      if all_open_exceptions.present?
        all_open_exceptions.map {|h,v| formatted_hours(v[:from_hour],v[:to_hour])}.join(", ")
      else
        formatted_hours(@from_hour, @to_hour)
      end
    end

    def formatted_hours(open_time, close_time)
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

    def open_all_day?(open_time, close_time)
      (open_time == "00:00" && close_time == "23:59") ? true : false
    end

    def closes_at_night?(close_time, date)
      exceptions = @all_exceptions.sort
      first_exception = exceptions.first.present? ? exceptions.first : []
      last_exception = exceptions.last.present? ? exceptions.last : []

      if first_exception.second.present? && last_exception.second.present? && first_exception.second[:from_hour] == "00:00" && last_exception.second[:status] == "OPEN"
        ['00:14','23:59','00:59'].include?(last_exception.second[:to_hour]) ? false : true
      elsif first_exception.second.present? && last_exception.second.present? && first_exception.second[:from_hour] == "00:00" && last_exception.second[:status] == "CLOSE"
        ['23:59'].include?(last_exception.second[:to_hour]) ? true : false
      else
        ['00:14','23:59','00:59'].include?(close_time) ? false : true
      end
    end

    def closed_all_day?(record)
      record[:type] == "EXCEPTION" && record[:status] == "CLOSE" && record[:from_hour] == "00:00" && record[:to_hour] == "23:59"
    end

    def parse_child(xml)
     xml.present? ? xml.text : ""
    end

    def xml_parser
      Nokogiri::XML
    end
  end
end
