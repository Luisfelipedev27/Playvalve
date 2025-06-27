module V1
  class UserController < ApplicationController


    private

    def user_params
      params.permit(:idfa, :rooted_device)
    end
  end
end
