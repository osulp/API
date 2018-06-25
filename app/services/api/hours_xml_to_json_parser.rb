#This returns a json object that contains an open time, close time, and the date, for a singular date passed back by the alma api
#This assumes that only a single date was queried out of alma.
#Input: XML from alma for ONE day
#output: JSON for ONE day with an open time, close time, and date
module API
  class HoursXmlToJsonParser
    def self.call(hours_xml)
      parse_xml(hours_xml)
    end

    private

    def self.parse_xml(hours_xml)
      json_data = {}
      parsed_xml = xml_parser.parse(hours_xml)
      day_list = parsed_xml.xpath("//day")
      hour_list = parsed_xml.xpath("//hour").map { |element| element.element_children.map(&:text) } 
      day_list.each_with_index do |day, i|
        data = {open_time: hour_list[i].empty? ? '00:00' : hour_list[i].first.to_s, 
                close_time: hour_list[i].empty? ? '00:00' : hour_list[i].second.to_s, 
                parsed_time: day.xpath("//date")[i].text.gsub("Z", "") }
        json_data[DateTime.parse(data[:parsed_time]).to_s] = build_json_from_data(data)
      end
      json_data.to_json
    end

    def self.build_json_from_data(data)
      { open: Time.parse(data[:open_time]).strftime("%l:%M%P"),
        close: Time.parse(data[:close_time]).strftime("%l:%M%P"),
        string_date: DateTime.parse(data[:parsed_time].to_s).strftime("%a, %b %e, %Y"),
        sortable_date: data[:parsed_time].to_s,
        formatted_hours: formatted_hours(data[:open_time], data[:close_time]),
        open_all_day: open_all_day?(data[:open_time], data[:close_time]),
        closes_at_night: closes_at_night?(data[:close_time])
      }
    end

    def self.open_all_day?(open_time, close_time)
      (open_time == "00:00" && close_time == "23:59") ? true : false
    end

    def self.closes_at_night?(close_time)
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
  end
end
