# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Alma do
  let(:alma) { described_class.new(date_from, date_to) }
  let(:base_url) { ENV['ALMA_OPEN_HOURS_URL'].to_s }
  let(:alma_key) { ENV['ALMA_API_KEY'].to_s }
  let(:url) { "#{base_url}?apikey=#{alma_key}&from=#{date_from}&to=#{date_to}" }
  let(:raw_json) do
    {
      'day': [
        {
          'date': '2019-06-24Z',
          'day_of_week': {
            'value': '2',
            'desc': 'Monday'
          },
          'hour': [
            {
              'from': '07:30',
              'to': '21:00'
            }
          ]
        }
      ]
    }.to_json
  end
  let(:date_from) { '2018-06-24' }
  let(:date_to) { '2018-06-24' }
  let(:cached_minutes) { '1' }

  before do
    ENV['ALMA_OPEN_HOURS_URL'] = 'https://url/to/alma/api'
    ENV['ALMA_API_KEY'] = 'almaapikey123'
    ENV['ALMA_CACHED_FOR'] = '720'

    stub_request(:get, url)
      .with(
        headers: {
          'Accept' => 'application/json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'User-Agent' => 'Ruby'
        }
      ).to_return(status: 200, body: raw_json, headers: {})
  end

  it 'sets a hash variable' do
    expect(alma.hash).to_not be_nil
  end

  it 'returns hours in json format' do
    expect(alma.hours_json).to_not be_nil
  end
end
