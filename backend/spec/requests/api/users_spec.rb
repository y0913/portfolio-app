require "rails_helper"

RSpec.describe "Api::Users", type: :request do
  describe "POST /api/users" do
    it "creates a user and starts a session" do
      expect {
        post "/api/users",
             params: {
               email_address: "new@example.com",
               password: "password123",
               password_confirmation: "password123"
             }.to_json,
             headers: { "CONTENT_TYPE" => "application/json" }
      }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.headers["Set-Cookie"]).to include("session_id=")
    end

    it "rejects a short password with 422" do
      post "/api/users",
           params: {
             email_address: "x@example.com",
             password: "short",
             password_confirmation: "short"
           }.to_json,
           headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to have_key("errors")
    end

    it "rejects an invalid email format with 422" do
      post "/api/users",
           params: {
             email_address: "not-an-email",
             password: "password123",
             password_confirmation: "password123"
           }.to_json,
           headers: { "CONTENT_TYPE" => "application/json" }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
