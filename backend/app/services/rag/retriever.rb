module Rag
  # Finds the most relevant DocumentChunks for a query against the shared
  # knowledge base (all ready documents in the instance). Documents are uploaded
  # by admins and visible to every authenticated user, so retrieval is not
  # scoped by user.
  class Retriever
    DEFAULT_K = 5

    def initialize(embedder: Embedding::Client.default)
      @embedder = embedder
    end

    # Returns Array<DocumentChunk> with `neighbor_distance` populated.
    def search(query, k: DEFAULT_K)
      return [] if query.blank?

      vector = @embedder.embed([query]).first

      DocumentChunk
        .joins(:document)
        .where(documents: { status: "ready" })
        .where(embedding_model: @embedder.model_name)
        .nearest_neighbors(:embedding, vector, distance: "cosine")
        .limit(k)
        .includes(:document)
    end
  end
end
