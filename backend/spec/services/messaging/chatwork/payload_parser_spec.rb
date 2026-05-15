require "rails_helper"

RSpec.describe Messaging::Chatwork::PayloadParser do
  subject(:parser) { described_class.new }

  let(:base_event) do
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
      "webhook_setting_id" => "abc",
      "webhook_event_type" => "message_created",
      "webhook_event_time" => 1700000000,
      "webhook_event" => base_event
    }
  end

  it "produces a normalized InboundMessage" do
    msg = parser.parse(payload)
    expect(msg).to be_a(Messaging::InboundMessage)
    expect(msg.platform).to eq(:chatwork)
    expect(msg.channel_id).to eq("12345")
    expect(msg.sender_id).to eq("678")
    expect(msg.message_id).to eq("999")
    expect(msg.body).to eq("返金期間は？")
  end

  it "strips ChatWork [To:] and [rp] tags from the body" do
    payload["webhook_event"]["body"] = "[To:42] [rp aid=42 to=12345-998]質問本体"
    msg = parser.parse(payload)
    expect(msg.body).to eq("質問本体")
  end

  it "accepts mention_to_me event type" do
    payload["webhook_event_type"] = "mention_to_me"
    expect { parser.parse(payload) }.not_to raise_error
  end

  it "raises on unsupported event types" do
    payload["webhook_event_type"] = "room_created"
    expect { parser.parse(payload) }.to raise_error(described_class::ParseError, /unsupported/)
  end

  it "raises when webhook_event is missing" do
    payload.delete("webhook_event")
    expect { parser.parse(payload) }.to raise_error(described_class::ParseError, /webhook_event/)
  end

  it "raises when required event fields are missing" do
    payload["webhook_event"].delete("room_id")
    expect { parser.parse(payload) }.to raise_error(described_class::ParseError, /required/)
  end

  it "raises when payload is not a Hash" do
    expect { parser.parse("not a hash") }.to raise_error(described_class::ParseError)
  end
end
