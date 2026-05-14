require "rails_helper"

RSpec.describe "Api::Sessions", type: :request do
  let!(:user) { create(:user) }

  describe "POST /api/session" do
    it "logs in with correct credentials and sets a signed session_id cookie" do
      post "/api/session",
           params: { email_address: user.email_address, password: "password123" }.to_json,
           headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body).to include("id" => user.id, "email_address" => user.email_address)
      expect(response.headers["Set-Cookie"]).to include("session_id=")
    end

    it "returns 401 for wrong password" do
      post "/api/session",
           params: { email_address: user.email_address, password: "wrong" }.to_json,
           headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/session" do
    it "returns 401 when not authenticated" do
      get "/api/session"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns current user when authenticated" do
      login_as(user)
      get "/api/session"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include("email_address" => user.email_address)
    end
  end

  describe "DELETE /api/session" do
    it "logs out and clears the cookie" do
      login_as(user)
      delete "/api/session"
      expect(response).to have_http_status(:no_content)
      # Subsequent request without re-login should fail
      get "/api/session"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
