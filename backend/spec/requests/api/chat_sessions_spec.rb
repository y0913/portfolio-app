require "rails_helper"

RSpec.describe "Api::ChatSessions", type: :request do
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }

  describe "POST /api/chat_sessions" do
    it "creates a session with default title when none given" do
      login_as(user)
      expect {
        post "/api/chat_sessions", params: {}.to_json, headers: { "CONTENT_TYPE" => "application/json" }
      }.to change(ChatSession, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)["title"]).to be_present
    end
  end

  describe "GET /api/chat_sessions/:id" do
    let!(:session) { create(:chat_session, user: user) }

    it "returns 404 when accessed by another user" do
      login_as(other_user)
      get "/api/chat_sessions/#{session.id}"
      expect(response).to have_http_status(:not_found)
    end

    it "returns session with empty messages" do
      login_as(user)
      get "/api/chat_sessions/#{session.id}"
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["id"]).to eq(session.id)
      expect(body["messages"]).to eq([])
    end
  end

  describe "POST /api/chat_sessions/:id/messages" do
    let!(:session) { create(:chat_session, user: user) }
    let!(:document) { create(:document, :ready, user: user, title: "Doc") }
    let!(:chunk) do
      create(:document_chunk, document: document, position: 0,
             content: "返金は購入から30日以内に承ります。", embedding_model: "stub-1024")
    end

    before { login_as(user) }

    it "saves user + assistant messages and returns both" do
      expect {
        post "/api/chat_sessions/#{session.id}/messages",
             params: { content: "返金は？" }.to_json,
             headers: { "CONTENT_TYPE" => "application/json" }
      }.to change { session.messages.count }.by(2)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["user_message"]["content"]).to eq("返金は？")
      expect(body["assistant_message"]["role"]).to eq("assistant")
    end

    it "returns 422 for blank content" do
      post "/api/chat_sessions/#{session.id}/messages",
           params: { content: "  " }.to_json,
           headers: { "CONTENT_TYPE" => "application/json" }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
