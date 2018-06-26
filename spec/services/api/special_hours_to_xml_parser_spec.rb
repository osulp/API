require 'rails_helper'

describe API::SpecialHoursXmlToJsonParser do
  let(:service) { described_class }
  let(:valid_special_hours_json) { File.read("spec/fixtures/alma_special_hours.json") }
  let(:xml) { File.read("spec/fixtures/alma_special_hours.xml") }

  describe "#call" do
    it "outputs JSON in a valid format for an event" do
      expect(JSON.parse(service.call(xml))["4"]["type"]).to eq "EVENT"
      expect(JSON.parse(service.call(xml))["4"]["desc"]).to eq "End of Term"
      expect(JSON.parse(service.call(xml))["4"]["from_date"]).to eq "2018-09-07Z"
      expect(JSON.parse(service.call(xml))["4"]["to_date"]).to eq ""
      expect(JSON.parse(service.call(xml))["4"]["from_hour"]).to eq ""
      expect(JSON.parse(service.call(xml))["4"]["to_hour"]).to eq ""
      expect(JSON.parse(service.call(xml))["4"]["day_of_week"]).to eq ""
      expect(JSON.parse(service.call(xml))["4"]["status"]).to eq "OPEN"
    end

    it "outputs JSON in a valid format for a holiday" do
      expect(JSON.parse(service.call(xml))["8"]["type"]).to eq "EXCEPTION"
      expect(JSON.parse(service.call(xml))["8"]["desc"]).to eq "New Year's Day (observed)"
      expect(JSON.parse(service.call(xml))["8"]["from_date"]).to eq "2019-01-01Z"
      expect(JSON.parse(service.call(xml))["8"]["to_date"]).to eq "2019-01-01Z"
      expect(JSON.parse(service.call(xml))["8"]["from_hour"]).to eq "00:00"
      expect(JSON.parse(service.call(xml))["8"]["to_hour"]).to eq "23:59"
      expect(JSON.parse(service.call(xml))["8"]["day_of_week"]).to eq "TUESDAY"
      expect(JSON.parse(service.call(xml))["8"]["status"]).to eq "CLOSE"
    end
  end
end
