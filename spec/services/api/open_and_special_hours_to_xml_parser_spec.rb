require 'rails_helper'

describe API::OpenAndSpecialHoursXmlToJsonParser do
  let(:service) { described_class }
  let(:api_output_json) { File.read("spec/fixtures/alma_nov_holiday_weeks.json") }
  let(:xml) { File.read("spec/fixtures/alma_open_and_special_hours.xml") }
  let(:dates) {["2018-11-11", "2018-11-24"]}

  describe "#call" do
    context "outputs JSON in a valid format for a november weeks 2018-11-11 to 2018-11-24" do
      let(:api_output_json) { File.read("spec/fixtures/alma_november.json") }
      let(:expected_json) { JSON.parse(api_output_json) }
      let(:dates) {["2018-11-01", "2018-11-30"]}

      NOV_TEST_DATES = (DateTime.parse("2018-11-01")..DateTime.parse("2018-11-30")).to_a.map {|d| d.strftime("%Y-%m-%d") }
      NOV_TEST_DATES.each do |date|
        it "outputs JSON in a valid format for #{date}" do 
          date_val = DateTime.parse(date).to_s
          expected_date_json = expected_json[date_val]
          expect(JSON.parse(service.call(xml,dates))[date_val]).to eq expected_date_json
        end
      end
    end

    context "outputs JSON in a valid format for the month of december 2018-12-01 to 2018-12-31" do
      let(:api_output_json) { File.read("spec/fixtures/alma_december.json") }
      let(:expected_json) { JSON.parse(api_output_json) }
      let(:dates) {["2018-12-01", "2018-12-31"]}

      DEC_TEST_DATES = (DateTime.parse("2018-12-01")..DateTime.parse("2018-12-31")).to_a.map {|d| d.strftime("%Y-%m-%d") }
      DEC_TEST_DATES.each do |date|
        it "outputs JSON in a valid format for #{date}" do 
          date_val = DateTime.parse(date).to_s
          expected_date_json = expected_json[date_val]
          expect(JSON.parse(service.call(xml,dates))[date_val]).to eq expected_date_json
        end
      end
    end
  end
end
