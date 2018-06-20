require 'rails_helper'

describe WidgetsController, type: :controller do
  describe "#show" do
    let(:day) { }
    let(:valid_json) { JSON.parse('{ "valid_json_with_data": {"data": "data"} }') }
    let(:valid_xml) { "<days><day><date>2018-06-03Z</date><from>00:00</from><to>23:59</to></day></days>" }
    let(:alma) { Alma.new(date_from, date_to) }
    let(:url) { "#{ENV['ALMA_OPEN_HOURS_URL']}?apikey=#{ENV['ALMA_API_KEY']}&from=#{date_from}&to=#{date_to}" }
    let(:xml) { File.read("spec/fixtures/alma_open_hours.xml") }
    let(:date_from) { "2018-06-18" }
    let(:date_to) { "2018-06-18" }
    let(:cached_minutes) { "1" }

    before do
      ENV['ALMA_OPEN_HOURS_URL'] = 'https://url/to/alma/api'
      ENV['ALMA_API_KEY'] = 'almaapikey123'
      ENV['ALMA_CACHED_FOR'] = '720'

      stub_request(:get, "https://url/to/alma/api?apikey=almaapikey123&from=2018-06-20&to=2018-06-26").
          with(
              headers: {
                  'Accept'=>'*/*',
                  'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                  'User-Agent'=>'Ruby'
              }).
          to_return(status: 200, body: "", headers: {})

      # stub_request(:get, url).
      #   with(
      #       headers: {
      #           'Accept'=>'*/*',
      #           'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      #           'User-Agent'=>'Ruby'
      #       }).
      #   to_return(status: 200, body: xml, headers: {})
    end

    context "When this week's hours widget is returned" do
      before do
        allow(API::HoursXmlToJsonParser).to receive(:call).with(anything()).and_return(valid_json)
        allow(alma).to receive(:xml_document).and_return(valid_xml)
      end

      it "responds to js" do
        get :show, params: { template: 'this_weeks_hours' }
        # expect(assigns(:hours)["valid_json_with_data"]["data"]).to eq "data"
      end
    end
  end
end
