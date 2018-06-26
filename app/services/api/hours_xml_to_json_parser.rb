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
      day_list = parsed_xml.xpath("//day")
      hour_list = parsed_xml.xpath("//hour").map { |element| element.element_children.map(&:text) }
      long_hour_list = parsed_xml.xpath("//hours").map { |element| element.element_children.map(&:text) } 
      closed_index = long_hour_list.include?([]) ? long_hour_list.index([]) : nil
      hour_list.insert(closed_index, []) unless closed_index.nil?
      extra_data = get_special_info_list(dates)
      day_list.each_with_index do |day, i|
        data = {open_time: hour_list[i].blank? ? '00:00' : hour_list[i].first.to_s, 
                close_time: hour_list[i].blank? ? '00:00' : hour_list[i].second.to_s, 
                parsed_time: day.xpath("//date")[i].text.gsub("Z", "") }
        json_data[DateTime.parse(data[:parsed_time]).to_s] = build_json_from_data(data, extra_data)
      end
      json_data.to_json
    end

    def self.build_json_from_data(data, extra_data)
      { open: Time.parse(data[:open_time]).strftime("%l:%M%P"),
        close: Time.parse(data[:close_time]).strftime("%l:%M%P"),
        string_date: DateTime.parse(data[:parsed_time].to_s).strftime("%a, %b %e, %Y"),
        sortable_date: data[:parsed_time].to_s,
        formatted_hours: formatted_hours(data[:open_time], data[:close_time]),
        open_all_day: open_all_day?(data[:open_time], data[:close_time]),
        closes_at_night: closes_at_night?(data[:close_time]),
        event_desc: get_desc_from_extra(data[:parsed_time], extra_data),
        event_status: get_status_from_extra(data[:parsed_time], extra_data)
      }
    end

    def self.get_desc_from_extra(day, extra_data)
      data = extra_data[DateTime.parse(day).to_s]
      data.present? ? data.first[:desc] : ''
    end

    def self.get_status_from_extra(day, extra_data)
      data = extra_data[DateTime.parse(day).to_s]
      data.present? ? data.first[:status] : ''
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

    def self.special_events
      API::SpecialHoursXmlToJsonParser.call(AlmaSpecialHours.new.xml_document)
    end

  end
end
