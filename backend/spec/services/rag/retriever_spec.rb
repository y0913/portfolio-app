require "rails_helper"

RSpec.describe Rag::Retriever do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:embedder) { Embedding::StubAdapter.new }

  it "returns chunks ordered by cosine similarity" do
    doc = create(:document, :ready, user: user)
    target_vec = embedder.embed(["返金は30日以内"]).first
    other_vec = embedder.embed(["まったく無関係なテキストでござる"]).first

    relevant = create(:document_chunk, document: doc, position: 0,
                      content: "返金は30日以内", embedding_model: embedder.model_name,
                      embedding: target_vec)
    _noise = create(:document_chunk, document: doc, position: 1,
                    content: "ノイズ", embedding_model: embedder.model_name,
                    embedding: other_vec)

    result = described_class.new(user: user, embedder: embedder).search("返金は30日以内")
    expect(result.first.id).to eq(relevant.id)
  end

  it "ignores documents that are not ready" do
    pending_doc = create(:document, user: user, status: "pending")
    create(:document_chunk, document: pending_doc, embedding_model: embedder.model_name,
                            embedding: embedder.embed(["x"]).first)

    result = described_class.new(user: user, embedder: embedder).search("x")
    expect(result).to be_empty
  end

  it "ignores chunks from other users" do
    doc = create(:document, :ready, user: other_user)
    create(:document_chunk, document: doc, embedding_model: embedder.model_name,
                            embedding: embedder.embed(["x"]).first)

    result = described_class.new(user: user, embedder: embedder).search("x")
    expect(result).to be_empty
  end

  it "ignores chunks with a different embedding_model" do
    doc = create(:document, :ready, user: user)
    create(:document_chunk, document: doc, embedding_model: "some-other-model",
                            embedding: embedder.embed(["x"]).first)

    result = described_class.new(user: user, embedder: embedder).search("x")
    expect(result).to be_empty
  end

  it "returns [] for blank query" do
    result = described_class.new(user: user, embedder: embedder).search("")
    expect(result).to eq([])
  end
end
