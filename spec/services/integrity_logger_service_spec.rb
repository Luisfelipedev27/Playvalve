require 'rails_helper'

RSpec.describe IntegrityLoggerService, type: :service do
  let(:valid_log_data) do
    {
      idfa: SecureRandom.uuid,
      ban_status: 'not_banned',
      ip: '192.168.1.1',
      rooted_device: false,
      country: 'US',
      proxy: false,
      vpn: false
    }
  end

  describe '#call' do
    context 'with valid log data' do
      it 'creates IntegrityLog record successfully' do
        expect {
          service = described_class.call(log_data: valid_log_data)
          expect(service).to be_success
        }.to change(IntegrityLog, :count).by(1)

        log = IntegrityLog.last
        expect(log.idfa).to eq(valid_log_data[:idfa])
        expect(log.ban_status).to eq(valid_log_data[:ban_status])
        expect(log.ip).to eq(valid_log_data[:ip])
        expect(log.rooted_device).to eq(valid_log_data[:rooted_device])
        expect(log.country).to eq(valid_log_data[:country])
        expect(log.proxy).to eq(valid_log_data[:proxy])
        expect(log.vpn).to eq(valid_log_data[:vpn])
      end

      it 'handles banned status' do
        banned_data = valid_log_data.merge(ban_status: 'banned', vpn: true)

        service = described_class.call(log_data: banned_data)

        expect(service).to be_success
        log = IntegrityLog.last
        expect(log.ban_status).to eq('banned')
        expect(log.vpn).to be true
      end

      it 'handles rooted device' do
        rooted_data = valid_log_data.merge(rooted_device: true, ban_status: 'banned')

        service = described_class.call(log_data: rooted_data)

        expect(service).to be_success
        log = IntegrityLog.last
        expect(log.rooted_device).to be true
        expect(log.ban_status).to eq('banned')
      end

      it 'handles proxy detection' do
        proxy_data = valid_log_data.merge(proxy: true, ban_status: 'banned')

        service = described_class.call(log_data: proxy_data)

        expect(service).to be_success
        log = IntegrityLog.last
        expect(log.proxy).to be true
        expect(log.ban_status).to eq('banned')
      end
    end
  end
end
