require 'rails_helper'

RSpec.describe UserStatusCheckerService, type: :service do
  let(:valid_params) { { idfa: SecureRandom.uuid, rooted_device: false } }
  let(:ip) { '192.168.1.1' }
  let(:country) { 'US' }

  before do
    redis_mock = double('Redis')
    allow(Rails.cache.redis).to receive(:with).and_yield(redis_mock)
    allow(redis_mock).to receive(:sismember).and_return(true)

    vpn_service_mock = double('VpnService', result: { proxy: false, vpn: false, tor: false, relay: false })
    allow(VpnApiClientService).to receive(:call).and_return(vpn_service_mock)
  end

  describe '#call' do
    context 'with valid parameters' do
      it 'returns success for allowed user' do
        service = described_class.call(user_params: valid_params, ip: ip, country: country)

        expect(service).to be_success
        expect(service.final_status_result).to eq('not_banned')
      end
    end

    context 'with invalid parameters' do
      it 'fails when idfa is nil' do
        invalid_params = valid_params.merge(idfa: nil)
        service = described_class.call(user_params: invalid_params, ip: ip, country: country)

        expect(service).not_to be_success
        expect(service.error_message).to eq('IDFA and IP are required')
      end

      it 'fails when ip is nil' do
        service = described_class.call(user_params: valid_params, ip: nil, country: country)

        expect(service).not_to be_success
        expect(service.error_message).to eq('IDFA and IP are required')
      end
    end

    context 'when user should be banned' do
      it 'bans user from non-whitelisted country' do
        redis_mock = double('Redis')
        allow(Rails.cache.redis).to receive(:with).and_yield(redis_mock)
        allow(redis_mock).to receive(:sismember).with('country_whitelist', 'CN').and_return(false)

        service = described_class.call(user_params: valid_params, ip: ip, country: 'CN')

        expect(service).to be_success
        expect(service.final_status_result).to eq('banned')
      end

      it 'bans user with rooted device' do
        rooted_params = valid_params.merge(rooted_device: true)
        service = described_class.call(user_params: rooted_params, ip: ip, country: country)

        expect(service).to be_success
        expect(service.final_status_result).to eq('banned')
      end

      it 'bans user with VPN detected' do
        vpn_service_mock = double('VpnService', result: { proxy: false, vpn: true, tor: false, relay: false })
        allow(VpnApiClientService).to receive(:call).and_return(vpn_service_mock)

        service = described_class.call(user_params: valid_params, ip: ip, country: country)

        expect(service).to be_success
        expect(service.final_status_result).to eq('banned')
      end

      it 'bans user with proxy detected' do
        vpn_service_mock = double('VpnService', result: { proxy: true, vpn: false, tor: false, relay: false })
        allow(VpnApiClientService).to receive(:call).and_return(vpn_service_mock)

        service = described_class.call(user_params: valid_params, ip: ip, country: country)

        expect(service).to be_success
        expect(service.final_status_result).to eq('banned')
      end

      it 'bans user with tor detected' do
        vpn_service_mock = double('VpnService', result: { proxy: false, vpn: false, tor: true, relay: false })
        allow(VpnApiClientService).to receive(:call).and_return(vpn_service_mock)

        service = described_class.call(user_params: valid_params, ip: ip, country: country)

        expect(service).to be_success
        expect(service.final_status_result).to eq('banned')
      end

      it 'bans user with relay detected' do
        vpn_service_mock = double('VpnService', result: { proxy: false, vpn: false, tor: false, relay: true })
        allow(VpnApiClientService).to receive(:call).and_return(vpn_service_mock)

        service = described_class.call(user_params: valid_params, ip: ip, country: country)

        expect(service).to be_success
        expect(service.final_status_result).to eq('banned')
      end
    end

    context 'when user already exists' do
      it 'returns banned status without re-checking for already banned user' do
        user = create(:user, :banned, idfa: valid_params[:idfa])

        service = described_class.call(user_params: valid_params, ip: ip, country: country)

        expect(service).to be_success
        expect(service.final_status_result).to eq('banned')
      end
    end
  end
end
