require "rails_helper"

RSpec.describe ProcessInboundMessageJob do
  let(:inbound) do
    Messaging::InboundMessage.new(
      platform: :chatwork,
      channel_id: "12345",
      sender_id: "678",
      message_id: "999",
      body: "返金期間は何日ですか？",
      raw: {}
    )
  end

  let(:answer_result) do
    Rag::Answerer::Result.new(
      content: "30日以内です。 [1]",
      citations: [{ number: 1, document_title: "返金ポリシー", position: 0,
                    excerpt: "30日以内", content: "30日以内であれば返品可能" }],
      chunks: []
    )
  end

  let(:client) { instance_double(Messaging::Chatwork::Client) }

  before do
    allow(Messaging::Client).to receive(:for).with(:chatwork).and_return(client)
    allow(client).to receive(:post)
  end

  it "runs RAG and posts the answer back via the client" do
    allow_any_instance_of(Rag::Answerer).to receive(:answer).and_return(answer_result)

    described_class.perform_now(inbound.to_h_serializable)

    expect(client).to have_received(:post) do |args|
      expect(args[:channel_id]).to eq("12345")
      outbound = args[:message]
      expect(outbound).to be_a(Messaging::OutboundMessage)
      expect(outbound.body).to eq("30日以内です。 [1]")
      expect(outbound.citations.size).to eq(1)
      expect(outbound.reply_to.message_id).to eq("999")
    end
  end

  it "notifies the channel and re-raises when RAG fails" do
    allow_any_instance_of(Rag::Answerer).to receive(:answer).and_raise(StandardError, "boom")

    expect {
      described_class.perform_now(inbound.to_h_serializable)
    }.to raise_error(StandardError, "boom")

    expect(client).to have_received(:post).with(
      hash_including(channel_id: "12345")
    )
    # Two posts attempted? No: only the fallback succeeded because RAG raised
    # before the first post. One call total.
    expect(client).to have_received(:post).once
  end
end
