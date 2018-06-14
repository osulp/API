require 'rails_helper'

describe API::HoursXmlToJsonParser do
  let(:service) { described_class }
  let(:xml) {}
  let(:formatted_time) {  }

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
        expect(service.call(xml)[formatted_time]["open"]).to eq "00:00"
        expect(service.call(xml)[formatted_time]["close"]).to eq "02:59"
        expect(service.call(xml)[formatted_time]["string_date"]).to eq "Fri, Jun  8, 2018"
        expect(service.call(xml)[formatted_time]["sortable_date"]).to eq "2018-06-08"
        expect(service.call(xml)[formatted_time]["formatted_hours"]).to eq "00:00 - 02:59"
        expect(service.call(xml)[formatted_time]["open_all_day"]).to eq false
        expect(service.call(xml)[formatted_time]["closes_at_night"]).to eq true
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
        expect(service.call(xml)[formatted_time]["open"]).to eq "00:00"
        expect(service.call(xml)[formatted_time]["close"]).to eq "02:59"
        expect(service.call(xml)[formatted_time]["string_date"]).to eq "Fri, Jun  8, 2018"
        expect(service.call(xml)[formatted_time]["sortable_date"]).to eq "2018-06-08"
        expect(service.call(xml)[formatted_time]["formatted_hours"]).to eq "00:00 - 02:59"
        expect(service.call(xml)[formatted_time]["open_all_day"]).to eq false
        expect(service.call(xml)[formatted_time]["closes_at_night"]).to eq true
      end
    end
  end
end
