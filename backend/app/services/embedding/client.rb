module Embedding
  # Factory + abstract interface for embedding providers.
  #
  # Concrete adapters must implement:
  #   #model_name -> String (stable identifier stored in document_chunks.embedding_model)
  #   #dimensions -> Integer
  #   #embed(texts) -> Array<Array<Float>>
  module Client
    class Error < StandardError; end

    class << self
      def default
        new(ENV.fetch("EMBEDDING_PROVIDER", default_provider_name))
      end

      def new(provider)
        case provider.to_s
        when "voyage"  then VoyageAdapter.new
        when "stub"    then StubAdapter.new
        else
          raise Error, "Unknown EMBEDDING_PROVIDER=#{provider.inspect}"
        end
      end

      private
        def default_provider_name
          Rails.env.production? ? "voyage" : "stub"
        end
    end
  end
end
