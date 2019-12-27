# frozen_string_literal: true

require 'rails_helper'

describe API::LibraryOpenHoursJson do
  let(:service) { described_class }
  let(:api_input_json) { File.read('spec/fixtures/alma_may_2019_raw.json') }
  let(:raw_hours) { JSON.parse(api_input_json) }
  let(:api_output_json) { File.read('spec/fixtures/alma_may_2019.json') }
  let(:expected_json) { JSON.parse(api_output_json) }

  describe '#call' do
    context 'outputs valid JSON between 2019-05-01 and 2019-05-31' do
      MAY_TEST_DATES = (DateTime.parse('2019-05-01')..DateTime.parse('2019-05-31')).to_a.map {|d| d.strftime('%Y-%m-%d') }
      MAY_TEST_DATES.each do |date|
        it "outputs JSON in a valid format for #{date}" do
          date_val = DateTime.parse(date).to_s
          expected_date_json = expected_json[date_val]
          expect(JSON.parse(service.call(raw_hours))[date_val]).to eq expected_date_json
        end
      end
    end

    context 'outputs valid JSON between 2019-06-01 and 2019-06-30' do
      let(:api_input_json) { File.read('spec/fixtures/alma_june_2019_raw.json') }
      let(:api_output_json) { File.read('spec/fixtures/alma_june_2019.json') }

      JUNE_TEST_DATES = (DateTime.parse('2019-06-01')..DateTime.parse('2019-06-30')).to_a.map {|d| d.strftime('%Y-%m-%d') }
      JUNE_TEST_DATES.each do |date|
        it "outputs JSON in a valid format for #{date}" do
          date_val = DateTime.parse(date).to_s
          expected_date_json = expected_json[date_val]
          expect(JSON.parse(service.call(raw_hours))[date_val]).to eq expected_date_json
        end
      end
    end

    # Limited services in java2
    context 'outputs valid JSON between 2020-01-01 and 2020-01-31' do
      let(:api_input_json) { File.read('spec/fixtures/alma_january_2020_raw.json') }
      let(:api_output_json) { File.read('spec/fixtures/alma_january_2020.json') }

      JANUARY_TEST_DATES = (DateTime.parse('2020-01-01')..DateTime.parse('2020-01-31')).to_a.map { |d| d.strftime('%Y-%m-%d') }
      JANUARY_TEST_DATES.each do |date|
        it "outputs JSON in a valid format for #{date}" do
          date_val = DateTime.parse(date).to_s
          expected_date_json = expected_json[date_val]
          expect(JSON.parse(service.call(raw_hours, true))[date_val]).to eq expected_date_json
        end
      end
    end
  end
end
