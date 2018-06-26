require 'rails_helper'

RSpec.describe WidgetsController, type: :controller do
  describe "GET #hours" do
    let(:day) { }
    let(:valid_json) { File.read("spec/fixtures/alma_open_hours.json") }
    let(:valid_xml) { File.read("spec/fixtures/alma_open_hours.xml") }
    let(:url) { "#{ENV['ALMA_OPEN_HOURS_URL']}?apikey=#{ENV['ALMA_API_KEY']}&from=#{date_from}&to=#{date_to}" }
    let(:date_from) { "2018-06-03" }
    let(:date_to) { "2018-06-09" }
    let(:dates) { [date_from, date_to] }
    let(:cached_minutes) { "1" }

    before do
      ENV['ALMA_OPEN_HOURS_URL'] = 'https://url/to/alma/api'
      ENV['ALMA_API_KEY'] = 'almaapikey123'
      ENV['ALMA_CACHED_FOR'] = '720'
    end

    context "When this week's hours widget is returned" do
      before do
        allow(API::HoursXmlToJsonParser).to receive(:call).with(valid_xml, dates).and_return(valid_json)
        allow_any_instance_of(Alma).to receive(:xml_document).and_return(valid_xml)
        allow_any_instance_of(Alma).to receive(:fetch).and_return(valid_xml)
      end

      it "responds to js" do
        post :hours, params: { template: 'this_weeks_hours', format: :js }
        expect(assigns(:hours)).to include(date_from)
        expect(assigns(:hours)).to include(date_to)
        expect(response.body).to include("This Week's Hours")
      end

      it "responds to html" do
        get :hours, params: { template: 'calendar', format: :html }
        expect(response.body).to include("widget_datepicker")
      end
    end
  end
end
