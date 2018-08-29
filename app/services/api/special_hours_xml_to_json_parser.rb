#This returns a json object that contains special dates info
#Input: XML from alma special hours
#output: JSON for every day with event info and closures
module API
  class SpecialHoursXmlToJsonParser
    def self.call(hours_xml)
      parse_xml(hours_xml)
    end

    private

    def self.parse_xml(hours_xml)
      json_data = {}
      parsed_xml = xml_parser.parse(hours_xml)
      special_day_list = parsed_xml.xpath("//open_hour")
      special_day_list.each_with_index do |day, i|
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
      upcoming_special_dates(json_data)
    end

    def self.upcoming_special_dates(json_data)
      # only include
      #
      # - items with type EXCEPTION or EVENT
      # - items with future dates

      json_data.select { |h,v| v[:type] == "EXCEPTION" || v[:type] == "EVENT" || upcoming_date?(v[:from_date], v[:to_date]) }.to_json
    end

    def self.upcoming_date?(from_date, to_date)
      # TODO: return true when current or upcoming date:
      # - items when date range [from_date, to_date] is in the future OR
      # - current date is within range [from_date, to_date]
      date_range = DateTime.parse(from_date)..DateTime.parse(to_date)
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
