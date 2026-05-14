# CORS configuration. Origins are env-driven so the same image can be promoted
# across staging/prod without code changes.
#
# Local dev uses http://localhost:3000.
# Production reads CORS_ORIGINS (comma-separated), e.g.
#   CORS_ORIGINS="https://portfolio-app.vercel.app,https://app.example.com"
allowed = if Rails.env.production?
  ENV.fetch("CORS_ORIGINS", "").split(",").map(&:strip).reject(&:empty?)
else
  ["http://localhost:3000"]
end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed)

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
