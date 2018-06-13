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
			day_list.each_with_index do |day, i|
				data = {open_time: day.xpath("//from")[i].text.to_s, close_time: day.xpath("//to")[i].text.to_s, parsed_time: day.xpath("//date")[i].text.gsub("Z", "") }
				json_data[DateTime.parse(data[:parsed_time]).to_s] = build_json_from_data(data)
			end
			json_data.to_json
		end

		def self.build_json_from_data(data)
			{ open: data[:open_time],
				close: data[:close_time],
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
				"#{open_time} - No Closing"
			elsif (open_time == "00:14")
				"Closes at #{close_time}"
			elsif (open_time == "00:00" && close_time == "23:59")
				"Open 24 Hours"
			elsif (open_time == "01:00" && close_time == "01:00")
				"Closed"
			else
				"#{open_time} - #{close_time}"
			end
		end

		def self.xml_parser
			Nokogiri::XML	
		end
  end
end