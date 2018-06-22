require 'rails_helper'

RSpec.describe AlmaSpecialHours do
  let(:special_hours_url_base) { "#{ENV['ALMA_SPECIAL_HOURS_URL']}" }
  let(:special_hours_url) { "#{ENV['ALMA_SPECIAL_HOURS_URL']}?apikey=#{apikey}" }
  let(:xml_special) { File.read("spec/fixtures/alma_special_hours.xml") }
  let(:cached_for) { "1" }
  let(:apikey) { ENV['ALMA_API_KEY'] }

  before do
    ENV['ALMA_OPEN_HOURS_URL'] = 'https://url/to/alma/api'
    ENV['ALMA_SPECIAL_HOURS_URL'] = 'https://url/to/alma/special/hours/api'
    ENV['ALMA_API_KEY'] = 'almaapikey123'
    ENV['ALMA_CACHED_FOR'] = '1'
  end

  it 'fetches the xml' do
    stub_request(:get, special_hours_url).
        with(
            headers: {
                'Accept'=>'*/*',
                'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'User-Agent'=>'Ruby'
            }).
        to_return(status: 200, body: xml_special, headers: {})

    expect(described_class.fetch(special_hours_url_base, apikey, cached_for)).to be_truthy
  end
end
