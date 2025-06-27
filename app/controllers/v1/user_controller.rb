module V1
  class UserController < ApplicationController
    def check_status
      ip = request.remote_ip
      country = request.headers['CF-IPCountry']

      service = UserStatusCheckerService.call(user_params: user_params, ip: ip, country: country)

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
  end
end
