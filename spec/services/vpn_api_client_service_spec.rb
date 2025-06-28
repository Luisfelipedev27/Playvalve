require 'rails_helper'

RSpec.describe VpnApiClientService, type: :service do
  let(:ip) { '8.8.8.8' }
  let(:cache_key) { "vpnapi:#{ip}" }
  let(:api_key) { 'test_api_key_123' }
  let(:valid_response_body) do
    {
      'ip' => '8.8.8.8',
      'security' => {
        'vpn' => false,
        'proxy' => false,
        'tor' => false,
        'relay' => false
      },
      'location' => {
        'country' => 'United States',
        'country_code' => 'US'
      }
    }
  end

  before do
    Rails.cache.delete(cache_key)
    stub_const('ENV', ENV.to_hash.merge('VPNAPI_KEY' => api_key))
  end

  describe '#call' do
    context 'with cached data' do
      let(:cached_data) { { proxy: true, vpn: false, tor: false, relay: false } }

      before do
        Rails.cache.write(cache_key, cached_data, expires_in: 24.hours)
      end

      it 'returns cached data without making API call' do
        service = described_class.call(ip: ip)

        expect(service).to be_success
        expect(service.result).to eq(cached_data)
      end
    end

    context 'with successful API response' do
      before do
        stub_request(:get, "https://vpnapi.io/api/#{ip}?key=#{api_key}")
          .to_return(
            status: 200,
            body: valid_response_body.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'makes API call and returns parsed data' do
        service = described_class.call(ip: ip)

        expect(service).to be_success
        expect(Rails.cache.read(cache_key)).to eq(service.result)
        expect(service.result[:proxy]).to be false
        expect(service.result[:vpn]).to be false
        expect(service.result[:tor]).to be false
        expect(service.result[:relay]).to be false
      end

      it 'handles vpn detection' do
        vpn_response = valid_response_body.deep_dup
        vpn_response['security']['vpn'] = true

        stub_request(:get, "https://vpnapi.io/api/#{ip}?key=#{api_key}")
          .to_return(
            status: 200,
            body: vpn_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        service = described_class.call(ip: ip)

        expect(service).to be_success
        expect(service.result[:vpn]).to be true
      end

      it 'handles tor detection' do
        tor_response = valid_response_body.deep_dup
        tor_response['security']['tor'] = true

        stub_request(:get, "https://vpnapi.io/api/#{ip}?key=#{api_key}")
          .to_return(
            status: 200,
            body: tor_response.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        service = described_class.call(ip: ip)

        expect(service).to be_success
        expect(service.result[:tor]).to be true
      end
    end

    context 'with API errors' do
      it 'handles timeout errors' do
        stub_request(:get, "https://vpnapi.io/api/#{ip}?key=#{api_key}").to_timeout

        service = described_class.call(ip: ip)

        expect(service).to be_success
        expect(service.result).to eq({ proxy: false, vpn: false, tor: false, relay: false })
      end

      it 'handles HTTP errors' do
        stub_request(:get, "https://vpnapi.io/api/#{ip}?key=#{api_key}")
          .to_return(status: 500, body: 'Internal Server Error')

        service = described_class.call(ip: ip)

        expect(service).to be_success
        expect(service.result).to eq({ proxy: false, vpn: false, tor: false, relay: false })
      end

      it 'handles connection errors' do
        stub_request(:get, "https://vpnapi.io/api/#{ip}?key=#{api_key}").to_raise(Faraday::ConnectionFailed)

        service = described_class.call(ip: ip)

        expect(service).to be_success
        expect(service.result).to eq({ proxy: false, vpn: false, tor: false, relay: false })
      end
    end
  end
end
