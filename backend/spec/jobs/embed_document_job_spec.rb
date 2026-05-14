require "rails_helper"

RSpec.describe EmbedDocumentJob do
  let(:user) { create(:user) }

  it "transitions a document to 'ready' and creates chunks" do
    document = create(:document, :with_text, user: user,
                      body: "返金は購入から30日以内です。" * 50)

    expect {
      described_class.perform_now(document.id)
    }.to change { document.reload.document_chunks.count }.from(0).to(be > 0)

    expect(document.status).to eq("ready")
    expect(document.document_chunks.first.embedding_model).to eq(Embedding::Client.default.model_name)
  end

  it "marks the document as 'failed' when text extraction fails" do
    document = create(:document, user: user, status: "pending") # no file attached

    described_class.perform_now(document.id)

    expect(document.reload.status).to eq("failed")
    expect(document.document_chunks.count).to eq(0)
  end
end
