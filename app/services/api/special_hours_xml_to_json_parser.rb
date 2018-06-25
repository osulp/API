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
            status: parse_child(day.xpath("status"))
        }
        json_data[i.to_s] = data
      end
      json_data.to_json
    end

    def self.parse_child(xml)
     xml.present? ? xml.text : ""
    end

    def self.xml_parser
      Nokogiri::XML
    end
  end
end
