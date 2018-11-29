require 'rails_helper'

RSpec.describe WidgetsController, type: :controller do
  describe "GET #hours" do
    let(:day) { }
    let(:valid_json) { File.read("spec/fixtures/alma_open_hours.json") }
    let(:valid_xml) { File.read("spec/fixtures/alma_open_hours.xml") }

    let(:valid_json_special) { File.read("spec/fixtures/alma_december.json") }
    let(:valid_xml_special) { File.read("spec/fixtures/alma_open_and_special_hours.xml") }

    let(:url) { "#{ENV['ALMA_OPEN_HOURS_URL']}?apikey=#{ENV['ALMA_API_KEY']}&from=#{date_from}&to=#{date_to}" }
    let(:url_special) { "#{ENV['ALMA_SPECIAL_HOURS_URL']}?apikey=#{ENV['ALMA_API_KEY']}&scope=#{ENV['ALMA_SPECIAL_HOURS_SCOPE']}" }
   
    let(:date_from) { "2018-12-01" }
    let(:date_to) { "2018-12-31" }
    let(:dates) { [date_from, date_to] }

    before do
      ENV['ALMA_SPECIAL_HOURS_URL'] = 'https://url/to/special/alma/api'
      ENV['ALMA_SPECIAL_HOURS_SCOPE'] = 'myscope'
      ENV['ALMA_OPEN_HOURS_URL'] = 'https://url/to/alma/api'
      ENV['ALMA_API_KEY'] = 'almaapikey123'
      ENV['ALMA_CACHED_FOR'] = '720'
    end

    context "When this week's hours widget is returned" do
      before do
        allow(subject).to receive(:alma_request).and_return(valid_json_special)
        allow(API::OpenAndSpecialHoursXmlToJsonParser).to receive(:call).with(valid_xml_special, dates).and_return(valid_json_special)
        allow_any_instance_of(AlmaSpecialHours).to receive(:xml_document).and_return(valid_xml_special)
        allow_any_instance_of(AlmaSpecialHours).to receive(:fetch_dates).and_return(valid_xml_special)
      end

      it "responds to js" do
        post :hours, params: { template: 'this_weeks_hours', format: :js }
        expect(assigns(:hours)).to include(date_from)
        expect(assigns(:hours)).to include(date_to)
      end

      it "responds to html" do
        get :hours, params: { template: 'calendar', format: :html }
        expect(response.body).to include("widget_datepicker")
      end
    end

    context "when no hours are available" do
      before do
        allow(subject).to receive(:alma_request).and_return(nil)
        allow(API::OpenAndSpecialHoursXmlToJsonParser).to receive(:call).with(valid_xml_special, dates).and_return(nil)
        allow_any_instance_of(AlmaSpecialHours).to receive(:xml_document).and_return(nil)
        allow_any_instance_of(AlmaSpecialHours).to receive(:fetch_dates).and_return(nil)
      end

      it "returns no hours available when rendering inline js" do
        post :hours, params: { template: 'this_weeks_hours', format: :js }
        expect(response.body).to include("No hours available.")
      end

      it "returns no hours available when rendering html" do
        get :hours, params: { template: 'calendar', format: :html }
        expect(response.body).to include("No hours available.")
      end

    end
  end
end
