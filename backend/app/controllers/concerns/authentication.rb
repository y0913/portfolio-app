module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end

    def require_admin(**options)
      before_action :require_admin!, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def require_admin!
      return if Current.user&.admin?
      render json: { error: "forbidden" }, status: :forbidden
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
    end

    def request_authentication
      render json: { error: "unauthorized" }, status: :unauthorized
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = session_cookie_options(session.id)
      end
    end

    def session_cookie_options(value)
      base = { value: value, httponly: true }
      if Rails.env.production?
        # Frontend (Vercel) and backend (Fly.io) are on different sites in prod,
        # so the browser only sends credentials when SameSite=None + Secure.
        base.merge(same_site: :none, secure: true)
      else
        base.merge(same_site: :lax)
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end
end
