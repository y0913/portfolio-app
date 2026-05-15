require "rails_helper"

RSpec.describe Messaging::Chatwork::Formatter do
  subject(:formatter) { described_class.new }

  let(:reply_to) do
    Messaging::InboundMessage.new(
      platform: :chatwork,
      channel_id: "12345",
      sender_id: "678",
      message_id: "999",
      body: "質問", raw: {}
    )
  end

  it "renders body only when there are no citations and no reply target" do
    msg = Messaging::OutboundMessage.new(body: "回答です", citations: [])
    expect(formatter.format(msg)).to eq("回答です")
  end

  it "prepends a [rp] reply marker when reply_to is given" do
    msg = Messaging::OutboundMessage.new(body: "回答", citations: [], reply_to: reply_to)
    out = formatter.format(msg)
    expect(out).to start_with("[rp aid=678 to=12345-999]")
    expect(out).to include("回答")
  end

  it "appends an [info] citations block when citations are present" do
    citations = [
      { number: 1, document_title: "返金ポリシー", position: 0, excerpt: "30日以内であれば返品可能" },
      { number: 2, document_title: "返金ポリシー", position: 1, excerpt: "送料は購入者負担" }
    ]
    msg = Messaging::OutboundMessage.new(body: "30日以内です [1][2]", citations: citations)
    out = formatter.format(msg)

    expect(out).to include("[info][title]参考資料[/title]")
    expect(out).to include("[1] 返金ポリシー (第1節)")
    expect(out).to include("30日以内であれば返品可能")
    expect(out).to include("[2] 返金ポリシー (第2節)")
    expect(out).to end_with("[/info]")
  end

  it "accepts citations with stringified keys (from JSON roundtrip)" do
    citations = [{ "number" => 1, "document_title" => "ハンドブック", "position" => 2, "excerpt" => "抜粋" }]
    msg = Messaging::OutboundMessage.new(body: "回答", citations: citations)
    expect(formatter.format(msg)).to include("[1] ハンドブック (第3節)")
  end
end
