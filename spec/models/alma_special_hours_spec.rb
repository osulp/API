require 'rails_helper'

RSpec.describe AlmaSpecialHours do
  let(:alma_special_hours) { described_class.new }
  let(:special_hours_url) { "#{ENV['ALMA_SPECIAL_HOURS_URL']}?apikey=#{ENV['ALMA_API_KEY']}&scope=#{ENV['ALMA_SPECIAL_HOURS_SCOPE']}" }
  let(:xml) { File.read("spec/fixtures/alma_special_hours.xml") }
  let(:cached_minutes) { "1" }

  before do
    ENV['ALMA_SPECIAL_HOURS_URL'] = 'https://url/to/alma/special/hours/api'
    ENV['ALMA_API_KEY'] = 'almaapikey123'
    ENV['ALMA_CACHED_FOR'] = '720'
    ENV['ALMA_SPECIAL_HOURS_SCOPE'] = 'MyBranch'

    stub_request(:get, special_hours_url).
        with(
            headers: {
                'Accept'=>'*/*',
                'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'User-Agent'=>'Ruby'
            }).
        to_return(status: 200, body: xml, headers: {})
  end

  it 'sets a hash variable' do
    expect(alma_special_hours.hash).to_not be_nil
  end

end
