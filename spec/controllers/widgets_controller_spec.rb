require 'rails_helper'

RSpec.describe WidgetsController, type: :controller do
  describe "GET #show" do
    let(:day) { }
    let(:valid_json) { File.read("spec/fixtures/alma_open_hours.json") }
    let(:valid_xml) { "<days><day><date>2018-06-03Z</date><from>00:00</from><to>23:59</to></day></days>" }
    let(:url) { "#{ENV['ALMA_OPEN_HOURS_URL']}?apikey=#{ENV['ALMA_API_KEY']}&from=#{date_from}&to=#{date_to}" }
    let(:xml) { File.read("spec/fixtures/alma_open_hours.xml") }
    let(:date_from) { "2018-06-03" }
    let(:date_to) { "2018-06-09" }
    let(:cached_minutes) { "1" }

    before do
      ENV['ALMA_OPEN_HOURS_URL'] = 'https://url/to/alma/api'
      ENV['ALMA_API_KEY'] = 'almaapikey123'
      ENV['ALMA_CACHED_FOR'] = '720'
    end

    context "When this week's hours widget is returned" do
      before do
        allow(API::HoursXmlToJsonParser).to receive(:call).with(valid_xml).and_return(valid_json)
        allow_any_instance_of(Alma).to receive(:xml_document).and_return(valid_xml)
        allow_any_instance_of(Alma).to receive(:fetch).and_return(valid_xml)
      end

      it "responds to js" do
        get :show, params: { template: 'this_weeks_hours', format: :js }
        expect(assigns(:hours)).to include("2018-06-03")
        expect(assigns(:hours)).to include("2018-06-09")
      end
    end
  end
end
