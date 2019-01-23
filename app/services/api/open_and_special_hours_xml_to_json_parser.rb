#This returns a json object that contains open and special dates info
#Input: XML from alma special hours
#output: JSON for every day with event info and closures
module API
  class OpenAndSpecialHoursXmlToJsonParser
    def self.call(hours_xml, dates)
      new(hours_xml, dates).call
    end

    def call
      parse_open_and_special_hours
    end

    private

    def initialize(hours_xml, dates)
      @dates = dates
      @raw_json_data = {}

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
        @raw_json_data[i.to_s] = data
      end

      @exceptions_data = get_exceptions_data
    end

    # Returns a hash with special dates for each given date in @dates in the
    # form: { date_string => [{exception_object1}, {exception_object2, etc...}]
    #
    # ==== Example
    #
    # input:
    #   @dates = ["2018-12-25","2018-12-25"]
    #   @raw_json_data = {"0" => {:type=>"WEEK"...},..."88"=>{:type=>"EXCEPTION"...}}
    #
    # output:
    #   {
    #    "2018-12-25T00:00:00+00:00"=>[{:type=>"EXCEPTION", :status=>"CLOSE", :desc=>"Christmas Day (observed)", :from_hour=>"00:00", :to_hour=>"23:59"}],
    #   }
    def get_exceptions_data
      Hash[(DateTime.parse(@dates.first)..DateTime.parse(@dates.last)).map do |d|
        [d.to_s, get_special_info(d, @raw_json_data)]
      end]
    end

    # Returns an array of hashes (exceptions objects) for a particular DateTime object from @raw_json_data
    #
    # ==== Example
    #
    # input:
    #   day = Tue, 25 Dec 2018 00:00:00 +0000
    #   @raw_json_data = {"0" => {:type=>"WEEK"...},..."88"=>{:type=>"EXCEPTION"...}}
    # output:
    #   [{:type=>"EXCEPTION", :status=>"CLOSE", :desc=>"Christmas Day (observed)", :from_hour=>"00:00", :to_hour=>"23:59"}]
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

    # Main parser function that uses lib_opening_hours to get the hours for
    # each day and then returns the objects in json format.
    #
    # ==== Example
    #
    # input: @dates = ["2018-12-27","2018-12-27"]
    # output: "{\"2018-12-27T00:00:00+00:00\":{\"open\":\" 7:30am\",\"close\":\" 6:00pm\",...}}"
    def parse_open_and_special_hours
      json_hours_data = {}
      date_range = DateTime.parse(@dates.first)..DateTime.parse(@dates.last)
      date_range.map.with_index do |day, i|
        json_hours_data[day.to_s] = lib_opening_hours(day)
      end
      json_hours_data.to_json
    end

    # Returns a hash with the expected hours data for a given date. It builds
    # it by getting the standard opening hours (type WEEK) first and then
    # it overrides the entries when special hours (type EXCEPTION) data is available
    # for that date.
    #
    # ==== Example
    #
    # input: date = Tue, 27 Dec 2018 00:00:00 +0000
    # output: {:open=>" 7:30am", :close=>" 6:00pm", :string_date=>"Thu, Dec 27, 2018",...}
    def lib_opening_hours(date)
      output_data = {}

      @from_hour = std_opening_hours(date).map { |h,v| v[:from_hour]}.first
      @to_hour = std_opening_hours(date).map { |h,v| v[:to_hour]}.first
      @event_desc = ""
      @event_status = ""
      @all_exceptions = {}
      @open_hours_and_exceptions_override = {}

      override_hours(date)

      output_data = {
        open:  @from_hour.present? ? Time.parse(@from_hour).strftime("%-l:%M%P") : "",
        close: @to_hour.present? ? Time.parse(@to_hour).strftime("%-l:%M%P") : "",
        string_date: date.strftime("%a, %b %-d, %Y"),
        sortable_date: date.strftime("%Y-%m-%d"),
        formatted_hours: all_formatted_hours,
        open_all_day: open_all_day?(@from_hour, @to_hour),
        closes_at_night: closes_at_night?(@to_hour, date),
        event_desc: @event_desc.present? ? @event_desc : "",
        event_status: @event_status.present? ? @event_status : "",
        all_open_hours: all_open_hours
      }
      output_data
    end

    # Returns a filtered version of @raw_json_data including only the
    # corresponding object of type WEEK (standard opening hours) that matches
    # the day of week for the given date.
    #
    # ==== Example
    #
    # input:
    #   date = Thu, 01 Nov 2018 00:00:00 +0000
    # output:
    #   {"1"=>{:type=>"WEEK", :desc=>"Thursday", :from_date=>"2014-08-14Z", :to_date=>"2019-08-14Z", :from_hour=>"00:00", :to_hour=>"23:59", :day_of_week=>"THURSDAY", :status=>"OPEN"}}
    def std_opening_hours(date)
      day_of_week = date.strftime("%A").upcase
      @raw_json_data.select {|h,v| v[:day_of_week] == day_of_week && v[:type] == "WEEK"}
    end

    # Overrides @from_hour, @to_hour, @event_desc, and @event_status for a given
    # date when there is a special date (exception) for that date.
    #
    # If there are multiple exceptions for that date, it rebuilds the list to insert missing
    # entries and then overrides @from_hour and @to_hour from the first exception with status OPEN.
    #
    # ==== Example
    #
    # input: date = Tue, 25 Dec 2018 00:00:00 +0000
    # output: 
    #   @from_hour = ''
    #   @to_hour = ''
    #   @event_desc = "Christmas Day (observed)"
    #   @event_status = "CLOSE"
    def override_hours(date)
      exceptions = @exceptions_data[date.to_s]
      return if exceptions.blank?

      build_all_exceptions_list(exceptions)

      if exceptions.count == 1
        override_from_first_exception(exceptions.first)
      elsif exceptions.count > 1
        add_missing_to_exceptions_list(exceptions)
        override_from_additional_exceptions
      end
    end

    def override_from_first_exception(first_exception)
      # if closed all day for date, then override @from_hour, @to_hour, etc
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

    def build_all_exceptions_list(exceptions)
      exceptions.each do |e|
        @open_hours_and_exceptions_override[Time.parse(e[:from_hour])] = {
          from_hour: e[:from_hour],
          to_hour: e[:to_hour],
          status: e[:status],
          desc: e[:desc]
        }
        @all_exceptions[Time.parse(e[:from_hour])] = e
      end
    end

    def add_missing_to_exceptions_list(exceptions)
      week_from = @from_hour
      week_to = @to_hour
      exceptions.each_with_index do |e, index|
        if exceptions[index-1].present? && exceptions[index].present?
          prev_pair = exceptions[index-1]
          if e[:status] == "CLOSE" && prev_pair[:status] == "CLOSE" && Time.parse(e[:from_hour]) > Time.parse(prev_pair[:to_hour])
            build_open_exception({
              tmp_from: Time.parse(prev_pair[:to_hour]),
              tmp_to: Time.parse(e[:from_hour]),
              week_from: week_from,
              week_to: week_to
            })
          end
        end
      end
    end

    def build_open_exception(args)
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

      if first_ex.second[:from_hour] == "00:00" && last_ex.second[:to_hour] == "23:59"
        all_open = @open_hours_and_exceptions_override.select {|h,v| v[:status] == "OPEN"}
        if all_open.count > 0
          # we take the first open available for the main open/close entry
          @from_hour = all_open.first.second[:from_hour]
          @to_hour = all_open.first.second[:to_hour]
        end
      end
    end

    def exception_hours(json_data)
      json_data.select { |h,v|
        (v[:type] == "EXCEPTION" && v[:status] == "CLOSE") || (v[:type] == "EXCEPTION" && v[:status] == "OPEN")
      }.to_json
    end

    def all_formatted_hours
      if all_open_exceptions.present?
        all_open_exceptions.map {|h,v| formatted_hours(v[:from_hour],v[:to_hour])}.join(", ")
      else
        formatted_hours(@from_hour, @to_hour)
      end
    end

    def all_open_hours
      if all_open_exceptions.present?
        all_open_exceptions.map{|h,v| {open: v[:from_hour], close: v[:to_hour]}}
      else
        [{open: @from_hour, close: @to_hour}]
      end
    end

    def all_open_exceptions
      @open_hours_and_exceptions_override.select {|h,v| v[:status] == "OPEN" }
    end

    def formatted_hours(open_time, close_time)
      if (close_time == "00:14" || partially_open?(open_time, close_time) == true)
        "#{Time.parse(open_time).strftime("%-l:%M%P")} - No Closing"
      elsif (open_time == "00:14")
        "Closes at #{close_time}"
      elsif (open_time == "00:00" && close_time == "23:59")
        "Open 24 Hours"
      elsif (open_time.eql? close_time)
        "Closed"
      else
        "#{Time.parse(open_time).strftime("%-l:%M%P")} - #{Time.parse(close_time).strftime("%-l:%M%P")}"
      end
    end

    def partially_open?(open_time, close_time)
      (open_time != "00:00" && close_time == "23:59") ? true : false
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
