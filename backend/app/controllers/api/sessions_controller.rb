module Api
  class SessionsController < ApplicationController
    allow_unauthenticated_access only: %i[create]
    rate_limit to: 10, within: 3.minutes, only: :create,
               with: -> { render json: { error: "rate_limited" }, status: :too_many_requests }

    def show
      render json: user_payload(Current.user)
    end

    def create
      user = User.authenticate_by(params.permit(:email_address, :password))
      if user
        start_new_session_for(user)
        render json: user_payload(user), status: :created
      else
        render json: { error: "invalid_credentials" }, status: :unauthorized
      end
    end

    def destroy
      terminate_session
      head :no_content
    end

    private
      def user_payload(user)
        { id: user.id, email_address: user.email_address, admin: user.admin? }
      end
  end
end
