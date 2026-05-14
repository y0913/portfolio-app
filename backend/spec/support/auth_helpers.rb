module AuthHelpers
  # Logs in a user via the real /api/session endpoint so the cookie jar gets the
  # signed session_id. Subsequent request-spec calls share the same cookie jar.
  def login_as(user, password: "password123")
    post "/api/session",
         params: { email_address: user.email_address, password: password }.to_json,
         headers: { "CONTENT_TYPE" => "application/json" }
    raise "login_as failed: #{response.status} #{response.body}" unless response.status == 201
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
