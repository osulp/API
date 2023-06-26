# frozen_string_literal: true

require 'rails_helper'

describe ApiController, type: :controller do
  describe "#hours" do
    let(:day) { }
    let(:valid_json) { JSON.parse('{ "valid_json_with_data": {"data": "data"} }') }
    let(:valid_xml) { "<days><day><date>2018-06-03Z</date><from>00:00</from><to>23:59</to></day></days>" }
    let(:valid_xml_special) { File.read("spec/fixtures/alma_open_and_special_hours.xml") }
    let(:alma) { Alma.new(date_from: date_from, date_to: date_to, limited: false) }
    let(:raw_hours_json) { File.read('spec/fixtures/alma_may_2019_raw.json') }
    let(:hours_json) { File.read('spec/fixtures/alma_may_2019.json') }
    let(:raw_json) do
      {
        'day': [
          {
            'date': '2019-06-24Z',
            'day_of_week': {
              'value': '2',
              'desc': 'Monday'
            },
            'hour': [
              {
                'from': '07:30',
                'to': '21:00'
              }
            ]
          }
        ]
      }.to_json
    end
    let(:alma_with_special_hours) { AlmaSpecialHours.new }
    let(:url) { "#{ENV['ALMA_OPEN_HOURS_URL']}?apikey=#{ENV['ALMA_API_KEY']}&from=#{date_from}&to=#{date_to}" }
    let(:open_and_special_hours_url) { "#{ENV['ALMA_SPECIAL_HOURS_URL']}?apikey=#{ENV['ALMA_API_KEY']}&scope=#{ENV['ALMA_SPECIAL_HOURS_SCOPE']}" }
    let(:xml) { File.read("spec/fixtures/alma_open_hours.xml") }
    let(:date_from) { '2019-06-24' }
    let(:date_to) { '2019-06-24' }
    let(:dates) { [date_from, date_to] }

    before do
      ENV['ALMA_OPEN_HOURS_URL'] = 'https://url/to/alma/api'
      ENV['ALMA_SPECIAL_HOURS_URL'] = 'https://url/to/special/alma/api'
      ENV['ALMA_SPECIAL_HOURS_SCOPE'] = 'myscope'
      ENV['ALMA_API_KEY'] = 'almaapikey123'
      ENV['ALMA_CACHED_FOR'] = '0'

      stub_request(:get, url).
        with(
            headers: {
                'Accept'=>'application/json',
                'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'User-Agent'=>'Ruby'
            }).
        to_return(status: 200, body: raw_json, headers: {})
    end

    context "When no day is provided" do
      let(:day) { '' }
      let(:date_from) { day }
      let(:date_to) { day }

      before do
        allow(API::OpenAndSpecialHoursXmlToJsonParser).to receive(:call).with(anything(), []).and_return(valid_json)
        controller.instance_variable_set(:@dates, dates)
        allow(AlmaHours).to receive(:fetch).with(anything()).and_return(nil)
      end

      it "returns nil" do
        post :hours
        expect(assigns(:hours)).to eq ""
      end
    end

    context "When a day is provided" do
      before do
        allow(API::OpenAndSpecialHoursXmlToJsonParser).to receive(:call).with(anything(), dates).and_return(valid_json)
        allow(Time.zone).to receive(:today).and_return(Time.parse(date_from))
        controller.instance_variable_set(:@dates, dates)
      end

      it "responds to json" do
        post :hours
        expect(assigns(:hours)).to_not be nil
      end
    end

    context "When a day is provided and no hours are available" do
      let(:day) { '2099-06-08' }
      let(:date_from) { day }
      let(:date_to) { day }
      before do
        allow(API::OpenAndSpecialHoursXmlToJsonParser).to receive(:call).with(anything(), dates).and_return(nil)
        controller.instance_variable_set(:@dates, dates)
        allow(AlmaHours).to receive(:fetch).with(anything()).and_return(nil)
      end

      it "returns nil" do
        post :hours
        expect(assigns(:hours)).to eq ""
      end
    end
  end
end
