require 'rails_helper'

describe ApiController, type: :controller do
  describe "#hours" do
    let(:day) { }
    let(:valid_json) { JSON.parse('{ "valid_json_with_data": {"data": "data"} }') }
    let(:valid_xml) { "<days><day><date>2018-06-03Z</date><from>00:00</from><to>23:59</to></day></days>" }
    let(:valid_xml_special) { File.read("spec/fixtures/alma_open_and_special_hours.xml") }
    let(:alma) { Alma.new(date_from, date_to) }
    let(:alma_with_special_hours) { AlmaSpecialHours.new }
    let(:url) { "#{ENV['ALMA_OPEN_HOURS_URL']}?apikey=#{ENV['ALMA_API_KEY']}&from=#{date_from}&to=#{date_to}" }
    let(:open_and_special_hours_url) { "#{ENV['ALMA_SPECIAL_HOURS_URL']}?apikey=#{ENV['ALMA_API_KEY']}&scope=#{ENV['ALMA_SPECIAL_HOURS_SCOPE']}" }
    let(:xml) { File.read("spec/fixtures/alma_open_hours.xml") }
    let(:date_from) { Time.zone.today.strftime("%Y-%m-%d") }
    let(:date_to) { Time.zone.today.strftime("%Y-%m-%d") }
    let(:dates) { [date_from, date_to] }
    let(:cached_minutes) { "1" }

    before do
      ENV['ALMA_OPEN_HOURS_URL'] = 'https://url/to/alma/api'
      ENV['ALMA_SPECIAL_HOURS_URL'] = 'https://url/to/special/alma/api'
      ENV['ALMA_SPECIAL_HOURS_SCOPE'] = 'myscope'
      ENV['ALMA_API_KEY'] = 'almaapikey123'
      ENV['ALMA_CACHED_FOR'] = '720'

      stub_request(:get, open_and_special_hours_url).
        with(
            headers: {
                'Accept'=>'*/*',
                'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'User-Agent'=>'Ruby'
            }).
        to_return(status: 200, body: "", headers: {})
    end

    context "When no day is provided" do
      before do
        allow(API::OpenAndSpecialHoursXmlToJsonParser).to receive(:call).with(anything(), dates).and_return(valid_json)
        allow(alma_with_special_hours).to receive(:xml_document).and_return(valid_xml_special)
      end

      it "responds to json" do
        post :hours
        expect(assigns(:hours)["valid_json_with_data"]["data"]).to eq "data"
      end
    end

    context "When a day is provided" do
      let(:day) { "2018-06-08" }
      before do
        allow(API::OpenAndSpecialHoursXmlToJsonParser).to receive(:call).with(anything(), dates).and_return(valid_json)
        allow(alma_with_special_hours).to receive(:xml_document).and_return(valid_xml_special)
      end

      it "responds to json" do
        post :hours
        expect(assigns(:hours)["valid_json_with_data"]["data"]).to eq "data"
      end
    end

    context "When a day is provided and no hours are available" do
      before do
        allow(alma_with_special_hours).to receive(:xml_document).and_return(nil)
        allow(API::OpenAndSpecialHoursXmlToJsonParser).to receive(:call).with(anything(), dates).and_return(nil)
      end

      it "responds to json" do
        post :hours
        expect(assigns(:hours)).to be_nil
      end
    end
  end
end
