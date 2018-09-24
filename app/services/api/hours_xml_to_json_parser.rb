#This returns a json object that contains an open time, close time, and the date, for a singular date passed back by the alma api
#This assumes that only a single date was queried out of alma.
#Input: XML from alma for ONE day
#output: JSON for ONE day with an open time, close time, and date
module API
  class HoursXmlToJsonParser
    def self.call(hours_xml, dates)
      parse_xml(hours_xml, dates)
    end

    private

    def self.parse_xml(hours_xml, dates)
      json_data = {}
      parsed_xml = xml_parser.parse(hours_xml)
      extra_data = get_special_info_list(dates)
      day_list = parsed_xml.xpath("//day")
      day_list.each_with_index do |day, i|
        data = {
          open: get_formatted_open_time(day),
          close: get_formatted_close_time(day),
          string_date: get_formatted_date(day),
          sortable_date: parse_child(day.xpath("date")).gsub("Z", ""),
          formatted_hours: get_formatted_hours(day),
          open_all_day: open_all_day?(day),
          closes_at_night: closes_at_night?(day),
          event_desc: get_desc_from_extra(day, extra_data),
          event_status: get_status_from_extra(day, extra_data)
        } 
        json_data[DateTime.parse(parse_child(day.xpath("date"))).to_s] = data
      end
      json_data.to_json
    end

    def self.parse_hours(xml)
      json_data = {}
      hours = xml.present? ? xml.xpath("hours") : []
      hours.each_with_index do |hour, i|
        data = {
          hour: parse_hour(hour)
        } 
        json_data[i.to_s] = data
      end
      json_data
    end

    def self.parse_hour(xml)
      json_data = {}
      hour = xml.present? ? xml.xpath("hour") : []
      hour.each_with_index do |h, i|
        data = {
          open_time: parse_child(h.xpath("from")),
          close_time: parse_child(h.xpath("to"))
        } 
        json_data[i.to_s] = data
      end
      json_data
    end

    def self.parse_open_time(day)
      hours = parse_hours(day)
      if hours_available?(hours) && hours["0"][:hour]["0"][:open_time].present?
        hours["0"][:hour]["0"][:open_time]
      end
    end

    def self.parse_close_time(day)
      hours = parse_hours(day)
      if hours_available?(hours) && hours["0"][:hour]["0"][:close_time].present?
        hours["0"][:hour]["0"][:close_time]
      end
    end

    def self.hours_available?(hours)
      hours.present? && hours["0"].present? && hours["0"][:hour].present? && hours["0"][:hour]["0"].present?
    end

    def self.get_formatted_open_time(day)
      open_time = parse_open_time(day)
      open_time.present? ? Time.parse(open_time).strftime("%l:%M%P") : ""
    end

    def self.get_formatted_close_time(day)
      close_time = parse_close_time(day)
      close_time.present? ? Time.parse(close_time).strftime("%l:%M%P") : ""
    end

    def self.get_formatted_date(day)
      date = parse_child(day.xpath("date"))
      DateTime.parse(date.to_s).strftime("%a, %b %e, %Y")
    end

    def self.get_formatted_hours(day)
      open_time = parse_open_time(day)
      close_time = parse_close_time(day)
      formatted_hours(open_time, close_time)
    end

    def self.get_desc_from_extra(day, extra_data)
      date = parse_child(day.xpath("date"))
      data = extra_data[DateTime.parse(date).to_s]
      data.present? ? data.first[:desc] : ''
    end

    def self.get_status_from_extra(day, extra_data)
      date = parse_child(day.xpath("date"))
      data = extra_data[DateTime.parse(date).to_s]
      data.present? ? data.first[:status] : ''
    end

    def self.open_all_day?(day)
      open_time = parse_open_time(day)
      close_time = parse_close_time(day)
      (open_time == "00:00" && close_time == "23:59") ? true : false
    end

    def self.closes_at_night?(day)
      close_time = parse_close_time(day)
      ['00:14','23:59','00:59'].include?(close_time) ? false : true
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

    def self.xml_parser
      Nokogiri::XML
    end

    def self.get_special_info_list(dates)
      Hash[(DateTime.parse(dates.first)..DateTime.parse(dates.last)).map do |d|
        [d.to_s, get_special_info(d)]
      end]
    end

    def self.get_special_info(day)
      info = []
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

    def self.parse_child(xml)
      xml.present? ? xml.text : ""
    end

    def self.special_events
      API::SpecialHoursXmlToJsonParser.call(AlmaSpecialHours.new.xml_document)
    end

  end
end
