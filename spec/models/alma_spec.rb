RSpec.describe Alma do
  let(:alma) { described_class.new(date_from, date_to) }
  let(:url) { "#{ENV['ALMA_OPEN_HOURS_URL']}?apikey=#{ENV['ALMA_API_KEY']}&from=#{date_from}&to=#{date_to}" }
  let(:xml) { File.read("spec/fixtures/alma_open_hours.xml") }
  let(:date_from) { "2018-06-03" }
  let(:date_to) { "2018-06-09" }

  before do
    ENV['ALMA_OPEN_HOURS_URL'] = 'https://url/to/alma/api'
    ENV['ALMA_API_KEY'] = 'almaapikey123'
    ENV['ALMA_CACHED_FOR'] = '720'

    stub_request(:get, url).
        with(
            headers: {
                'Accept'=>'*/*',
                'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
                'User-Agent'=>'Ruby'
            }).
        to_return(status: 200, body: xml, headers: {})
  end

  it 'sets a hash variable' do
    expect(alma.hash).to_not be_nil
  end

  it 'has open_hours' do
    expect(alma.open_hours).to_not be_nil
    expect(alma.hash).to_not be_nil
  end
end
