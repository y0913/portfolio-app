module Api
  class DocumentsController < ApplicationController
    require_admin only: %i[create destroy]

    MAX_FILE_SIZE = 2.megabytes
    ALLOWED_EXTENSIONS = %w[.txt .md .markdown].freeze

    # All authenticated users can list/view the shared knowledge base.
    def index
      documents = Document.order(created_at: :desc).map { serialize(_1) }
      render json: { documents: documents }
    end

    def show
      document = Document.find(params[:id])
      render json: serialize(document, include_chunks: true)
    end

    # Admin-only. Uploaded documents are shared across all users.
    def create
      file = params[:file]
      unless file.respond_to?(:original_filename)
        return render json: { error: "file is required" }, status: :unprocessable_entity
      end

      unless ALLOWED_EXTENSIONS.include?(File.extname(file.original_filename).downcase)
        return render json: { error: "unsupported file type" }, status: :unprocessable_entity
      end

      if file.size > MAX_FILE_SIZE
        return render json: { error: "file too large (max 2 MB)" }, status: :unprocessable_entity
      end

      title = params[:title].presence || File.basename(file.original_filename, ".*")

      document = Current.user.documents.build(title: title, status: "pending")
      document.file.attach(io: file.tempfile, filename: file.original_filename,
                           content_type: file.content_type || "text/plain")

      if document.save
        EmbedDocumentJob.perform_later(document.id)
        render json: serialize(document), status: :created
      else
        render json: { errors: document.errors.as_json(full_messages: true) }, status: :unprocessable_entity
      end
    end

    def destroy
      document = Document.find(params[:id])
      document.destroy!
      head :no_content
    end

    private
      def serialize(document, include_chunks: false)
        json = {
          id: document.id,
          title: document.title,
          status: document.status,
          chunks_count: document.document_chunks.count,
          filename: document.file.attached? ? document.file.filename.to_s : nil,
          byte_size: document.file.attached? ? document.file.byte_size : nil,
          created_at: document.created_at,
          updated_at: document.updated_at
        }
        if include_chunks
          json[:chunks] = document.document_chunks.order(:position).map do |c|
            { id: c.id, position: c.position, content: c.content }
          end
        end
        json
      end
  end
end
