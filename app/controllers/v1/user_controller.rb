module V1
  class UserController < ApplicationController
    def check_status
      country = request.headers['CF-IPCountry']

      service = UserStatusCheckerService.call(user_params: user_params, ip: get_client_ip, country: country)

      if service.success?
        render json: { ban_status: service.final_status_result }, status: :ok
      else
        render json: { error: 'Internal server error' }, status: :internal_server_error
      end
    end

    private

    def user_params
      params.permit(:idfa, :rooted_device)
    end

    def get_client_ip
      remote_ip = request.remote_ip

      if remote_ip.in?(['127.0.0.1', '::1', 'localhost'])
        '8.8.8.8'
      else
        remote_ip
      end
    end
  end
end
