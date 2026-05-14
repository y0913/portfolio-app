require "rails_helper"

RSpec.describe Rag::Answerer do
  let(:admin) { create(:user, :admin) }
  let(:embedder) { Embedding::StubAdapter.new }
  let(:llm) { Llm::StubAdapter.new }

  before do
    doc = create(:document, :ready, user: admin, title: "返金ポリシー")
    create(:document_chunk, document: doc, position: 0,
           content: "商品到着から30日以内であれば、未開封・未使用に限り返品を承ります。",
           embedding_model: embedder.model_name,
           embedding: embedder.embed(["商品到着から30日以内であれば、未開封・未使用に限り返品を承ります。"]).first)
  end

  describe "#answer" do
    let(:retriever) { Rag::Retriever.new(embedder: embedder) }
    subject(:answerer) { described_class.new(retriever: retriever, llm: llm) }

    it "returns a result with content and citations" do
      result = answerer.answer("返金期間は？")
      expect(result.content).to be_present
      expect(result.citations).to be_an(Array)
      expect(result.citations.first).to include(
        :number, :document_id, :document_title, :chunk_id, :position, :excerpt, :content
      )
    end

    it "numbers citations starting from 1" do
      result = answerer.answer("返金期間は？")
      expect(result.citations.first[:number]).to eq(1)
    end
  end

  describe "#stream_answer" do
    let(:retriever) { Rag::Retriever.new(embedder: embedder) }
    subject(:answerer) { described_class.new(retriever: retriever, llm: llm) }

    it "yields citations first, then deltas, then done" do
      events = []
      answerer.stream_answer("返金期間は？") { |type, payload| events << [type, payload] }

      types = events.map(&:first)
      expect(types.first).to eq(:citations)
      expect(types.last).to eq(:done)
      expect(types).to include(:delta)
    end

    it "concatenated deltas equal the final answer" do
      final = nil
      deltas = []
      answerer.stream_answer("返金期間は？") do |type, payload|
        deltas << payload if type == :delta
        final = payload if type == :done
      end
      expect(deltas.join).to eq(final)
    end
  end
end
