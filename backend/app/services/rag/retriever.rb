module Rag
  # Finds the most relevant DocumentChunks for a query among a user's ready
  # documents. Pure retrieval — no LLM call.
  class Retriever
    DEFAULT_K = 5

    def initialize(user:, embedder: Embedding::Client.default)
      @user = user
      @embedder = embedder
    end

    # Returns Array<DocumentChunk> with `neighbor_distance` populated.
    def search(query, k: DEFAULT_K)
      return [] if query.blank?

      vector = @embedder.embed([query]).first

      DocumentChunk
        .joins(:document)
        .where(documents: { user_id: @user.id, status: "ready" })
        .where(embedding_model: @embedder.model_name)
        .nearest_neighbors(:embedding, vector, distance: "cosine")
        .limit(k)
        .includes(:document)
    end
  end
end
