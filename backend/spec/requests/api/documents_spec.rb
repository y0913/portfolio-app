require "rails_helper"

RSpec.describe "Api::Documents", type: :request do
  let!(:admin)  { create(:user, :admin) }
  let!(:member) { create(:user) }

  describe "GET /api/documents" do
    it "requires authentication" do
      get "/api/documents"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns the shared knowledge base to any authenticated user" do
      admin_doc  = create(:document, user: admin, title: "Admin doc")
      other_doc  = create(:document, user: admin, title: "Another admin doc")

      login_as(member)
      get "/api/documents"

      expect(response).to have_http_status(:ok)
      titles = JSON.parse(response.body).fetch("documents").map { _1["title"] }
      expect(titles).to contain_exactly(admin_doc.title, other_doc.title)
    end
  end

  describe "POST /api/documents" do
    let(:file) do
      Rack::Test::UploadedFile.new(StringIO.new("hello world"), "text/markdown", original_filename: "sample.md")
    end

    it "returns 403 for non-admin members" do
      login_as(member)
      expect {
        post "/api/documents", params: { file: file, title: "Hello" }
      }.not_to change(Document, :count)
      expect(response).to have_http_status(:forbidden)
    end

    it "creates a document and enqueues an embedding job as admin" do
      login_as(admin)
      expect {
        post "/api/documents", params: { file: file, title: "Hello" }
      }.to change(Document, :count).by(1)
        .and have_enqueued_job(EmbedDocumentJob)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body).to include("title" => "Hello", "status" => "pending")
    end

    it "rejects unsupported file types (admin)" do
      login_as(admin)
      bad = Rack::Test::UploadedFile.new(StringIO.new("PK..."), "application/pdf", original_filename: "x.pdf")
      post "/api/documents", params: { file: bad }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/documents/:id" do
    let!(:document) { create(:document, user: admin) }

    it "returns 403 when deleted by a non-admin" do
      login_as(member)
      delete "/api/documents/#{document.id}"
      expect(response).to have_http_status(:forbidden)
    end

    it "destroys the document for an admin (any document, since the KB is shared)" do
      login_as(admin)
      expect {
        delete "/api/documents/#{document.id}"
      }.to change(Document, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
