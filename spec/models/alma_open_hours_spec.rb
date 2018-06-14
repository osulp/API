require 'rails_helper'

RSpec.describe AlmaOpenHours do
  let(:url) { "http://server.name.bogus/20170101/blah.rss" }
  let(:cached_minutes) { "30" }
  let(:date) { "20170101" }
  let(:xml) { '<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"></rss>' }

  it 'fails with an invalid date' do
    # expect { described_class.fetch("123", url, cached_minutes) }.to raise_error
  end
  it 'fails with an invalid uri' do
    # expect { described_class.fetch(date, "blahblahblah", cached_minutes) }.to raise_error
  end
  it 'fetches the rss feed' do
    # stub_request(:get, url)
    #     .with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'})
    #     .to_return(:status => 200, :body => xml, :headers => {})
    #
    # expect(described_class.fetch(date, url, cached_minutes)).to be_truthy
  end
end