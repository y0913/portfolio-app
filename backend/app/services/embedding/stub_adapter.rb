require "digest"

module Embedding
  # Deterministic fake embedding for local development / tests.
  # Same input text always produces the same vector. Vector values are in [-1, 1].
  # Useful so the RAG pipeline can run end-to-end without API keys.
  class StubAdapter
    MODEL = "stub-1024".freeze
    DIMENSIONS = 1024

    def model_name = MODEL
    def dimensions = DIMENSIONS

    def embed(texts)
      texts.map { |t| vectorize(t) }
    end

    private
      def vectorize(text)
        seed = Digest::SHA256.digest(text).unpack("L*").first
        rng = Random.new(seed)
        vec = Array.new(DIMENSIONS) { rng.rand(-1.0..1.0) }
        # L2 normalize so cosine distance behaves sensibly.
        norm = Math.sqrt(vec.sum { |x| x * x })
        norm.zero? ? vec : vec.map { |x| x / norm }
      end
  end
end
