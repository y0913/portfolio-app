class EmbedDocumentJob < ApplicationJob
  queue_as :default

  CHUNK_SIZE = 800   # characters
  CHUNK_OVERLAP = 80
  ALLOWED_CONTENT_TYPES = %w[text/plain text/markdown application/octet-stream].freeze

  def perform(document_id)
    document = Document.find(document_id)
    document.update!(status: "processing")

    text = extract_text(document)
    if text.blank?
      document.update!(status: "failed")
      return
    end

    chunks = split_into_chunks(text)
    embedder = Embedding::Client.default
    vectors = embedder.embed(chunks)

    DocumentChunk.transaction do
      document.document_chunks.delete_all
      chunks.each_with_index do |content, i|
        document.document_chunks.create!(
          content: content,
          position: i,
          embedding_model: embedder.model_name,
          embedding: vectors[i]
        )
      end
    end

    document.update!(status: "ready")
  rescue StandardError => e
    Rails.logger.error("EmbedDocumentJob failed for document=#{document_id}: #{e.class} #{e.message}")
    Document.where(id: document_id).update_all(status: "failed")
    raise
  end

  private
    def extract_text(document)
      return "" unless document.file.attached?

      content_type = document.file.content_type.to_s
      unless ALLOWED_CONTENT_TYPES.include?(content_type) ||
             document.file.filename.to_s.match?(/\.(txt|md|markdown)\z/i)
        Rails.logger.warn("Unsupported content type: #{content_type}")
        return ""
      end

      document.file.download.force_encoding("UTF-8")
    end

    def split_into_chunks(text)
      return [] if text.blank?

      cleaned = text.gsub(/\r\n?/, "\n").strip
      chunks = []
      i = 0
      while i < cleaned.length
        chunks << cleaned[i, CHUNK_SIZE]
        i += CHUNK_SIZE - CHUNK_OVERLAP
      end
      chunks.reject(&:blank?)
    end
end
