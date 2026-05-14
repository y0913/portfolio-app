require "rails_helper"

RSpec.describe "Api::Documents", type: :request do
  let!(:user) { create(:user) }
  let!(:other_user) { create(:user) }

  describe "GET /api/documents" do
    it "requires authentication" do
      get "/api/documents"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns only the current user's documents" do
      mine = create(:document, user: user, title: "Mine")
      _theirs = create(:document, user: other_user, title: "Theirs")

      login_as(user)
      get "/api/documents"

      expect(response).to have_http_status(:ok)
      titles = JSON.parse(response.body).fetch("documents").map { _1["title"] }
      expect(titles).to contain_exactly("Mine")
      expect(JSON.parse(response.body)["documents"].first["id"]).to eq(mine.id)
    end
  end

  describe "POST /api/documents" do
    before { login_as(user) }

    it "creates a document and enqueues an embedding job" do
      file = Rack::Test::UploadedFile.new(StringIO.new("hello world"), "text/markdown", original_filename: "sample.md")

      expect {
        post "/api/documents", params: { file: file, title: "Hello" }
      }.to change(Document, :count).by(1)
        .and have_enqueued_job(EmbedDocumentJob)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body).to include("title" => "Hello", "status" => "pending")
    end

    it "rejects unsupported file types" do
      file = Rack::Test::UploadedFile.new(StringIO.new("PK..."), "application/pdf", original_filename: "x.pdf")
      post "/api/documents", params: { file: file }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/documents/:id" do
    let!(:document) { create(:document, user: user) }

    it "requires the document to belong to current user" do
      login_as(other_user)
      delete "/api/documents/#{document.id}"
      expect(response).to have_http_status(:not_found)
    end

    it "destroys the document for its owner" do
      login_as(user)
      expect {
        delete "/api/documents/#{document.id}"
      }.to change(Document, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end
end
