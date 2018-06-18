require 'rails_helper'

describe ApiController, type: :controller do
  describe "#hours" do
    let(:day) { }
    let(:api) { double("API") }
    let(:service) { double("API::HoursXmlToJsonParser") }
    let(:valid_json) { JSON.parse('{ "valid_json_with_data": {"data": "data"} }') }
    let(:valid_xml) { "<days><day><date>2018-06-03Z</date><from>00:00</from><to>23:59</to></day></days>" }

    context "When no day is provided" do
      before do
        allow(service).to receive(:parse).with(anything()).and_return(valid_json)
        #allow(api).to recveive(:query).with(day).and_return(valid_xml)
      end

      it "responds to json" do
        #expect()
      end
    end

    context "When a day is provided" do
      let(:day) { "2018-06-08" }
      before do
        allow(service).to receive(:parse).with(anything()).and_return(valid_json)
        #allow(api).to recveive(:query).with(day).and_return(valid_xml)
      end

      it "responds to json" do
        #expect()
      end
    end
  end
  describe "#multi_day_hours" do
    let(:day) { }
    let(:api) { double("API") }
    let(:service) { double("API::HoursXmlToJsonParser") }
    let(:valid_json) { JSON.parse('{ "valid_json_with_data": {"data": "data"} }') }
    let(:valid_xml) { "<days><day><date>2018-06-03Z</date><from>00:00</from><to>23:59</to></day><day><date>2018-06-04Z</date><from>01:00</from><to>21:59</to></day></days>" }

    context "When a day is provided" do
      let(:beginning_day) { "2018-06-03" }
      let(:ending_day) { "2018-06-04" }
      before do
        allow(service).to receive(:parse).with(anything()).and_return(valid_json)
        #allow(api).to recveive(:query).with(beginning_day, ending_day).and_return(valid_xml)
      end

      it "responds to json" do
        #expect()
      end
    end
  end
end
