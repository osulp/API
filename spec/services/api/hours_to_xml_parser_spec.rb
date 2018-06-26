require 'rails_helper'

describe API::HoursXmlToJsonParser do
  let(:service) { described_class }
  let(:xml) {}
  let(:formatted_time) {  }
  let(:dates) {["2018-06-08", "2018-06-08"]}
  let(:valid_special_hours_json) { File.read("spec/fixtures/alma_special_hours.json") }
  let(:special_hours_xml) { File.read("spec/fixtures/alma_special_hours.xml") }

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
  end
end
