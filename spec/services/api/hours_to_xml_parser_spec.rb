require 'rails_helper'

describe API::HoursXmlToJsonParser do
  let(:service) { described_class }
  let(:xml) {}
  let(:formatted_time) {  }
  let(:dates) {["2018-06-08", "2018-06-08"]}
  let(:valid_special_hours_json) { File.read("spec/fixtures/alma_special_hours.json") }

  describe "#call" do
    context "when only one day is requested" do
      let(:formatted_time) { DateTime.parse("2018-06-08").to_s }
      let(:xml) {
        '<days>
          <day>
            <date>2018-06-08Z</date>
            <day_of_week desc="Friday">6</day_of_week>
            <hours>
              <hour>
                <from>00:00</from>
                <to>02:59</to>
              </hour>
            </hours>
          </day>
        </days>'
      }
      it "outputs JSON in a valid format" do
        allow(API::SpecialHoursXmlToJsonParser).to receive(:call).with(anything()).and_return(valid_special_hours_json)
        allow(service).to receive(:special_events).and_return(valid_special_hours_json)
        expect(JSON.parse(service.call(xml, dates))[formatted_time]["open"]).to eq "12:00am"
        expect(JSON.parse(service.call(xml, dates))[formatted_time]["close"]).to eq " 2:59am"
        expect(JSON.parse(service.call(xml, dates))[formatted_time]["string_date"]).to eq "Fri, Jun  8, 2018"
        expect(JSON.parse(service.call(xml, dates))[formatted_time]["sortable_date"]).to eq "2018-06-08"
        expect(JSON.parse(service.call(xml, dates))[formatted_time]["formatted_hours"]).to eq "12:00am - 2:59am"
        expect(JSON.parse(service.call(xml, dates))[formatted_time]["open_all_day"]).to eq false
        expect(JSON.parse(service.call(xml, dates))[formatted_time]["closes_at_night"]).to eq true
      end
    end
    context "when multiple days are requested" do
      let(:formatted_time) { DateTime.parse("2018-06-08").to_s }
      let(:xml) {
        '<days>
          <day>
            <date>2018-06-03Z</date>
            <day_of_week desc="Sunday">1</day_of_week>
            <hours>
              <hour>
                <from>13:00</from>
                <to>23:59</to>
              </hour>
            </hours>
          </day>
          <day>
            <date>2018-06-08Z</date>
            <day_of_week desc="Friday">6</day_of_week>
            <hours>
              <hour>
                <from>00:00</from>
                <to>02:59</to>
              </hour>
            </hours>
          </day>
        </days>'
      }
      it "outputs JSON in a valid format" do
        allow(API::SpecialHoursXmlToJsonParser).to receive(:call).with(anything()).and_return(valid_special_hours_json)
        allow(service).to receive(:special_events).and_return(valid_special_hours_json)
        expect(JSON.parse(service.call(xml, dates))[formatted_time]["open"]).to eq "12:00am"
        expect(JSON.parse(service.call(xml, dates))[formatted_time]["close"]).to eq " 2:59am"
        expect(JSON.parse(service.call(xml, dates))[formatted_time]["string_date"]).to eq "Fri, Jun  8, 2018"
        expect(JSON.parse(service.call(xml, dates))[formatted_time]["sortable_date"]).to eq "2018-06-08"
        expect(JSON.parse(service.call(xml, dates))[formatted_time]["formatted_hours"]).to eq "12:00am - 2:59am"
        expect(JSON.parse(service.call(xml, dates))[formatted_time]["open_all_day"]).to eq false
        expect(JSON.parse(service.call(xml, dates))[formatted_time]["closes_at_night"]).to eq true
      end
    end
    context "when seven days are requested (holiday week)" do
      let(:dates) {["2018-11-18", "2018-11-24"]}
      let(:sunday) { DateTime.parse("2018-11-18").to_s }
      let(:monday) { DateTime.parse("2018-11-19").to_s }
      let(:tuesday) { DateTime.parse("2018-11-20").to_s }
      let(:wednesday) { DateTime.parse("2018-11-21").to_s }
      let(:thursday) { DateTime.parse("2018-11-22").to_s }
      let(:friday) { DateTime.parse("2018-11-23").to_s }
      let(:saturday) { DateTime.parse("2018-11-24").to_s }

      let(:xml) { File.read("spec/fixtures/alma_holiday_week.xml") }

      before do
        allow(API::SpecialHoursXmlToJsonParser).to receive(:call).with(anything()).and_return(valid_special_hours_json)
        allow(service).to receive(:special_events).and_return(valid_special_hours_json)
      end

      it "outputs JSON in a valid format for sunday" do
        expect(JSON.parse(service.call(xml, dates))[sunday]["open"]).to eq "10:00am"
        expect(JSON.parse(service.call(xml, dates))[sunday]["close"]).to eq "11:59pm"
        expect(JSON.parse(service.call(xml, dates))[sunday]["formatted_hours"]).to eq "10:00am -11:59pm"
        expect(JSON.parse(service.call(xml, dates))[sunday]["sortable_date"]).to eq "2018-11-18"
        expect(JSON.parse(service.call(xml, dates))[sunday]["formatted_hours"]).to eq "10:00am -11:59pm"
        expect(JSON.parse(service.call(xml, dates))[sunday]["open_all_day"]).to eq false
        expect(JSON.parse(service.call(xml, dates))[sunday]["closes_at_night"]).to eq false
        expect(JSON.parse(service.call(xml, dates))[sunday]["event_desc"]).to eq ""
        expect(JSON.parse(service.call(xml, dates))[sunday]["event_status"]).to eq ""
      end
      it "outputs JSON in a valid format for monday" do
        expect(JSON.parse(service.call(xml, dates))[monday]["open"]).to eq "12:00am"
        expect(JSON.parse(service.call(xml, dates))[monday]["close"]).to eq "11:59pm"
        expect(JSON.parse(service.call(xml, dates))[monday]["string_date"]).to eq "Mon, Nov 19, 2018"
        expect(JSON.parse(service.call(xml, dates))[monday]["sortable_date"]).to eq "2018-11-19"
        expect(JSON.parse(service.call(xml, dates))[monday]["formatted_hours"]).to eq "Open 24 Hours"
        expect(JSON.parse(service.call(xml, dates))[monday]["open_all_day"]).to eq true
        expect(JSON.parse(service.call(xml, dates))[monday]["closes_at_night"]).to eq false
        expect(JSON.parse(service.call(xml, dates))[monday]["event_desc"]).to eq ""
        expect(JSON.parse(service.call(xml, dates))[monday]["event_status"]).to eq ""
      end
      it "outputs JSON in a valid format for tuesday" do
        expect(JSON.parse(service.call(xml, dates))[tuesday]["open"]).to eq "12:00am"
        expect(JSON.parse(service.call(xml, dates))[tuesday]["close"]).to eq "11:59pm"
        expect(JSON.parse(service.call(xml, dates))[tuesday]["string_date"]).to eq "Tue, Nov 20, 2018"
        expect(JSON.parse(service.call(xml, dates))[tuesday]["sortable_date"]).to eq "2018-11-20"
        expect(JSON.parse(service.call(xml, dates))[tuesday]["formatted_hours"]).to eq "Open 24 Hours"
        expect(JSON.parse(service.call(xml, dates))[tuesday]["open_all_day"]).to eq true
        expect(JSON.parse(service.call(xml, dates))[tuesday]["closes_at_night"]).to eq false
        expect(JSON.parse(service.call(xml, dates))[tuesday]["event_desc"]).to eq ""
        expect(JSON.parse(service.call(xml, dates))[tuesday]["event_status"]).to eq ""
        
      end
      it "outputs JSON in a valid format for wednesday" do
        expect(JSON.parse(service.call(xml, dates))[wednesday]["open"]).to eq "12:00am"
        expect(JSON.parse(service.call(xml, dates))[wednesday]["close"]).to eq "10:00pm"
        expect(JSON.parse(service.call(xml, dates))[wednesday]["string_date"]).to eq "Wed, Nov 21, 2018"
        expect(JSON.parse(service.call(xml, dates))[wednesday]["sortable_date"]).to eq "2018-11-21"
        expect(JSON.parse(service.call(xml, dates))[wednesday]["formatted_hours"]).to eq "12:00am -10:00pm"
        expect(JSON.parse(service.call(xml, dates))[wednesday]["open_all_day"]).to eq false
        expect(JSON.parse(service.call(xml, dates))[wednesday]["closes_at_night"]).to eq true
        expect(JSON.parse(service.call(xml, dates))[wednesday]["event_desc"]).to eq ""
        expect(JSON.parse(service.call(xml, dates))[wednesday]["event_status"]).to eq ""
        
      end
      it "outputs JSON in a valid format for thursday" do
        expect(JSON.parse(service.call(xml, dates))[thursday]["open"]).to eq ""
        expect(JSON.parse(service.call(xml, dates))[thursday]["close"]).to eq ""
        expect(JSON.parse(service.call(xml, dates))[thursday]["string_date"]).to eq "Thu, Nov 22, 2018"
        expect(JSON.parse(service.call(xml, dates))[thursday]["sortable_date"]).to eq "2018-11-22"
        expect(JSON.parse(service.call(xml, dates))[thursday]["formatted_hours"]).to eq "Closed"
        expect(JSON.parse(service.call(xml, dates))[thursday]["open_all_day"]).to eq false
        expect(JSON.parse(service.call(xml, dates))[thursday]["closes_at_night"]).to eq true
        expect(JSON.parse(service.call(xml, dates))[thursday]["event_desc"]).to eq "Thanksgiving holiday"
        expect(JSON.parse(service.call(xml, dates))[thursday]["event_status"]).to eq "CLOSE"
        
      end
      it "outputs JSON in a valid format for friday" do
        expect(JSON.parse(service.call(xml, dates))[friday]["open"]).to eq ""
        expect(JSON.parse(service.call(xml, dates))[friday]["close"]).to eq ""
        expect(JSON.parse(service.call(xml, dates))[friday]["string_date"]).to eq "Fri, Nov 23, 2018"
        expect(JSON.parse(service.call(xml, dates))[friday]["sortable_date"]).to eq "2018-11-23"
        expect(JSON.parse(service.call(xml, dates))[friday]["formatted_hours"]).to eq "Closed"
        expect(JSON.parse(service.call(xml, dates))[friday]["open_all_day"]).to eq false
        expect(JSON.parse(service.call(xml, dates))[friday]["closes_at_night"]).to eq true
        expect(JSON.parse(service.call(xml, dates))[friday]["event_desc"]).to eq "Thanksgiving holiday"
        expect(JSON.parse(service.call(xml, dates))[friday]["event_status"]).to eq "CLOSE"
        
      end
      it "outputs JSON in a valid format for saturday" do
        expect(JSON.parse(service.call(xml, dates))[saturday]["open"]).to eq "10:00am"
        expect(JSON.parse(service.call(xml, dates))[saturday]["close"]).to eq "10:00pm"
        expect(JSON.parse(service.call(xml, dates))[saturday]["string_date"]).to eq "Sat, Nov 24, 2018"
        expect(JSON.parse(service.call(xml, dates))[saturday]["sortable_date"]).to eq "2018-11-24"
        expect(JSON.parse(service.call(xml, dates))[saturday]["formatted_hours"]).to eq "10:00am -10:00pm"
        expect(JSON.parse(service.call(xml, dates))[saturday]["open_all_day"]).to eq false
        expect(JSON.parse(service.call(xml, dates))[saturday]["closes_at_night"]).to eq true
        expect(JSON.parse(service.call(xml, dates))[saturday]["event_desc"]).to eq ""
        expect(JSON.parse(service.call(xml, dates))[saturday]["event_status"]).to eq ""
      end
    end
  end
end
