require 'rails_helper'

describe ApiController, type: :controller do
  describe "#hours" do
    let(:day) { }
    let(:api) { double("Alma") }
    let(:service) { double("API::HoursXmlToJsonParser") }
    let(:valid_json) { JSON.parse('{ "valid_json_with_data": {"data": "data"} }') }
    let(:valid_xml) { "<days><day><date>2018-06-03Z</date><from>00:00</from><to>23:59</to></day></days>" }

    context "When no day is provided" do
      before do
        assigns(:dates, JSON.parse('{"dates":[]}')
        allow(service).to receive(:parse).with(anything()).and_return(valid_json)
        allow(api).to recveive(:new).with(anything()).and_return(valid_xml)
      end

      it "responds to json" do
        expect(response.header['Content-Type']).to include 'application/json'
      end
    end

    context "When a day is provided" do
      let(:day) { "2018-06-08" }
      before do
        allow(service).to receive(:parse).with(anything()).and_return(valid_json)
        allow(api).to recveive(:new).with(day).and_return(valid_xml)
      end

      it "responds to json" do
        expect(response.header['Content-Type']).to include 'application/json'
      end
    end
  end
end