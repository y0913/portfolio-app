require "rails_helper"

RSpec.describe "POST /api/webhooks/chatwork", type: :request do
  let(:secret) { "test-webhook-secret" }

  let(:event) do
    {
      "message_id" => "999",
      "room_id" => 12345,
      "account_id" => 678,
      "body" => "返金期間は？",
      "send_time" => 1700000000
    }
  end

  let(:payload) do
    {
      "webhook_event_type" => "message_created",
      "webhook_event" => event
    }
  end

  let(:raw_body) { payload.to_json }
  let(:signature) { sign(raw_body, secret) }

  def sign(body, key)
    Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", key, body))
  end

  around do |ex|
    original_secret = ENV["CHATWORK_WEBHOOK_TOKEN"]
    original_bot_id = ENV["CHATWORK_BOT_ACCOUNT_ID"]
    ENV["CHATWORK_WEBHOOK_TOKEN"] = secret
    ENV.delete("CHATWORK_BOT_ACCOUNT_ID")
    ex.run
  ensure
    ENV["CHATWORK_WEBHOOK_TOKEN"] = original_secret
    ENV["CHATWORK_BOT_ACCOUNT_ID"] = original_bot_id
  end

  def post_webhook(body:, sig: signature)
    headers = {
      "CONTENT_TYPE" => "application/json",
      "X-ChatWorkWebhookSignature" => sig
    }
    post "/api/webhooks/chatwork", params: body, headers: headers
  end

  it "queues a job and returns 200 on a valid signed payload" do
    expect(ProcessInboundMessageJob).to receive(:perform_later).once

    post_webhook(body: raw_body)

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["status"]).to eq("queued")
  end

  it "returns 401 on invalid signature" do
    expect(ProcessInboundMessageJob).not_to receive(:perform_later)
    post_webhook(body: raw_body, sig: "invalid")
    expect(response).to have_http_status(:unauthorized)
  end

  it "returns 400 on invalid JSON" do
    expect(ProcessInboundMessageJob).not_to receive(:perform_later)
    bad_body = "not json"
    post_webhook(body: bad_body, sig: sign(bad_body, secret))
    expect(response).to have_http_status(:bad_request)
  end

  it "ignores webhook events from the bot account itself" do
    ENV["CHATWORK_BOT_ACCOUNT_ID"] = "678"
    expect(ProcessInboundMessageJob).not_to receive(:perform_later)

    post_webhook(body: raw_body)

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)["status"]).to eq("ignored")
  end

  it "ignores unsupported event types (returns 200 to stop retries)" do
    payload["webhook_event_type"] = "room_created"
    body = payload.to_json
    expect(ProcessInboundMessageJob).not_to receive(:perform_later)

    post_webhook(body: body, sig: sign(body, secret))

    expect(response).to have_http_status(:ok)
  end

  it "returns 503 when the webhook token is not configured" do
    ENV.delete("CHATWORK_WEBHOOK_TOKEN")
    expect(ProcessInboundMessageJob).not_to receive(:perform_later)

    post_webhook(body: raw_body)

    expect(response).to have_http_status(:service_unavailable)
  end
end
