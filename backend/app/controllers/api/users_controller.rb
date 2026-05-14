module Api
  class UsersController < ApplicationController
    allow_unauthenticated_access only: %i[create]

    def create
      user = User.new(user_params)
      if user.save
        start_new_session_for(user)
        render json: { id: user.id, email_address: user.email_address }, status: :created
      else
        render json: { errors: user.errors.as_json(full_messages: true) }, status: :unprocessable_entity
      end
    end

    private
      def user_params
        params.permit(:email_address, :password, :password_confirmation)
      end
  end
end
