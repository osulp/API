require 'rails_helper'

describe API::OpenAndSpecialHoursXmlToJsonParser do
  let(:service) { described_class }
  let(:alma_nov_holiday_weeks_json) { File.read("spec/fixtures/alma_nov_holiday_weeks.json") }
  let(:xml) { File.read("spec/fixtures/alma_open_and_special_hours.xml") }
  let(:dates) {["2018-11-11", "2018-11-24"]}

  describe "#call" do
    context "outputs JSON in a valid format for a november weeks 2018-11-11 to 2018-11-24" do
      let(:expected_json) { JSON.parse(alma_nov_holiday_weeks_json) }

      TEST_DATES = {
        '0': '2018-11-11',
        '1': '2018-11-12',
        '2': '2018-11-13',
        '3': '2018-11-14',
        '4': '2018-11-15',
        '5': '2018-11-16',
        '6': '2018-11-17',
        '7': '2018-11-18',
        '8': '2018-11-19',
        '9': '2018-11-20',
        '10': '2018-11-21',
        '11': '2018-11-22',
        '12': '2018-11-23',
        '13': '2018-11-24'
      }

      TEST_DATES.each do |i, date|
        it "outputs JSON in a valid format for #{date}" do 
          date_val = DateTime.parse(date).to_s
          expected_date_json = expected_json[date_val]
          expect(JSON.parse(service.call(xml,dates))[date_val]).to eq expected_date_json
        end
      end  

    end
  end
end
