require 'rails_helper'

RSpec.describe AlmaHours do
  let(:url) { "#{ENV['ALMA_OPEN_HOURS_URL']}?apikey=#{apikey}&from=#{date_from}&to=#{date_to}" }
  let(:xml) { File.read("spec/fixtures/alma_open_hours.xml") }
  let(:date_from) { "2018-06-03" }
  let(:date_to) { "2018-06-09" }
  let(:cached_for) { "1" }
  let(:apikey) { ENV['ALMA_API_KEY'] }

  before do
    ENV['ALMA_OPEN_HOURS_URL'] = 'https://url/to/alma/api'
    ENV['ALMA_API_KEY'] = 'almaapikey123'
    ENV['ALMA_CACHED_FOR'] = '720'
  end

  it 'fetches the xml' do
    stub_request(:get, url).
        with(
            headers: {
                'Accept'=>'*/*',
                'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'User-Agent'=>'Ruby'
            }).
        to_return(status: 200, body: xml, headers: {})

    expect(described_class.fetch(date_from, date_to, url, apikey, cached_for)).to be_truthy
  end
end
