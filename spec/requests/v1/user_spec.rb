require 'rails_helper'

RSpec.describe "V1::Users", type: :request do
  let(:valid_params) { { idfa: SecureRandom.uuid, rooted_device: false } }
  let(:headers) { { 'Content-Type' => 'application/json' } }

  describe "POST /v1/user/check_status" do
    before do
      allow(Rails.cache.redis).to receive(:with).and_yield(redis_mock)

      vpn_service_mock = double('VpnApiService', result: { proxy: false, vpn: false, tor: false, relay: false })

      allow(VpnApiClientService).to receive(:call).and_return(vpn_service_mock)
    end

    let(:redis_mock) { double('Redis') }

    context "when user should be allowed" do
      before do
        allow(redis_mock).to receive(:sismember).with('country_whitelist', 'US').and_return(true)
      end

      it "returns not_banned for valid user from whitelisted country" do
        headers['CF-IPCountry'] = 'US'

        post '/v1/user/check_status', params: valid_params.to_json, headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['ban_status']).to eq('not_banned')
      end

      it "returns not_banned when no country header is present" do
        post '/v1/user/check_status', params: valid_params.to_json, headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['ban_status']).to eq('not_banned')
      end
    end

    context "when user should be banned" do
      before do
        allow(redis_mock).to receive(:sismember).with('country_whitelist', 'CN').and_return(false)
        allow(redis_mock).to receive(:sismember).with('country_whitelist', 'US').and_return(true)
      end

      it "bans user from non-whitelisted country" do
        headers['CF-IPCountry'] = 'CN'

        post '/v1/user/check_status', params: valid_params.to_json, headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['ban_status']).to eq('banned')
      end

      it "bans user with rooted device" do
        headers['CF-IPCountry'] = 'US'
        params = valid_params.merge(rooted_device: true)

        post '/v1/user/check_status', params: params.to_json, headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['ban_status']).to eq('banned')
      end
    end

    context "when user already exists" do
      before do
        allow(redis_mock).to receive(:sismember).and_return(true)
      end

      it "returns banned status for already banned user without re-checking" do
        user = create(:user, :banned, idfa: valid_params[:idfa])
        headers['CF-IPCountry'] = 'US'

        post '/v1/user/check_status', params: valid_params.to_json, headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['ban_status']).to eq('banned')
      end

      it "re-runs checks for not_banned user" do
        user = create(:user, idfa: valid_params[:idfa])
        allow(redis_mock).to receive(:sismember).with('country_whitelist', 'CN').and_return(false)
        headers['CF-IPCountry'] = 'CN'

        post '/v1/user/check_status', params: valid_params.to_json, headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['ban_status']).to eq('banned')

        expect(user.reload.ban_status).to eq('banned')
      end
    end

    context "with invalid parameters" do
      it "returns error when idfa is missing" do
        post '/v1/user/check_status', params: { rooted_device: false }.to_json, headers: headers

        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)['error']).to eq('Internal server error')
      end

      it "returns error when idfa is blank" do
        post '/v1/user/check_status', params: { idfa: '', rooted_device: false }.to_json, headers: headers

        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)['error']).to eq('Internal server error')
      end

      it "handles missing rooted_device parameter gracefully" do
        allow(redis_mock).to receive(:sismember).with('country_whitelist', 'US').and_return(true)
        headers['CF-IPCountry'] = 'US'

        post '/v1/user/check_status', params: { idfa: SecureRandom.uuid }.to_json, headers: headers

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['ban_status']).to eq('not_banned')
      end
    end

    context "data persistence" do
      before do
        allow(redis_mock).to receive(:sismember).with('country_whitelist', 'US').and_return(true)
        headers['CF-IPCountry'] = 'US'
      end

      it "creates User record for new user" do
        expect {
          post '/v1/user/check_status', params: valid_params.to_json, headers: headers
        }.to change(User, :count).by(1)

        user = User.find_by(idfa: valid_params[:idfa])
        expect(user.ban_status).to eq('not_banned')
      end

      it "creates IntegrityLog record" do
        expect {
          post '/v1/user/check_status', params: valid_params.to_json, headers: headers
        }.to change(IntegrityLog, :count).by(1)

        log = IntegrityLog.last
        expect(log.idfa).to eq(valid_params[:idfa])
        expect(log.ban_status).to eq('not_banned')
        expect(log.country).to eq('US')
        expect(log.rooted_device).to eq(false)
      end
    end
  end
end
