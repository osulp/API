# frozen_string_literal: true

require 'rails_helper'

describe API::LibraryOpenHoursJson do
  let(:service) { described_class }
  let(:api_input_json) { File.read("spec/fixtures/alma_may_2019_raw.json") }
  let(:raw_hours) { JSON.parse(api_input_json) }
  let(:api_output_json) { File.read("spec/fixtures/alma_may_2019.json") }
  let(:expected_json) { JSON.parse(api_output_json) }
  let(:dates) {["2019-05-01", "2018-05-31"]}

  describe "#call" do
    context "outputs JSON in a valid format for the month of may 2019-05-01 to 2019-05-31" do
      MAY_TEST_DATES = (DateTime.parse('2019-05-01')..DateTime.parse('2019-05-31')).to_a.map {|d| d.strftime("%Y-%m-%d") }
      MAY_TEST_DATES.each do |date|
        it "outputs JSON in a valid format for #{date}" do
          date_val = DateTime.parse(date).to_s
          expected_date_json = expected_json[date_val]
          expect(JSON.parse(service.call(raw_hours))[date_val]).to eq expected_date_json
        end
      end
    end

    context "outputs JSON in a valid format for the month of june 2019-06-01 to 2019-06-30" do
      let(:api_input_json) { File.read("spec/fixtures/alma_june_2019_raw.json") }
      let(:api_output_json) { File.read("spec/fixtures/alma_june_2019.json") }
      let(:dates) {["2019-06-01", "2019-06-30"]}

      JUNE_TEST_DATES = (DateTime.parse('2019-06-01')..DateTime.parse('2019-06-30')).to_a.map {|d| d.strftime("%Y-%m-%d") }
      JUNE_TEST_DATES.each do |date|
        it "outputs JSON in a valid format for #{date}" do
          date_val = DateTime.parse(date).to_s
          expected_date_json = expected_json[date_val]
          expect(JSON.parse(service.call(raw_hours))[date_val]).to eq expected_date_json
        end
      end
    end
  end
end
