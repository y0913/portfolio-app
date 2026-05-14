module Llm
  # Factory + abstract interface for LLM providers.
  #
  # Concrete adapters must implement:
  #   #model_name -> String
  #   #generate(messages, **opts) -> String
  #   #generate_stream(messages, **opts) { |chunk| ... } -> nil  (Phase 4)
  #
  # messages: Array<{ role: "user"|"assistant"|"system", content: String }>
  module Client
    class Error < StandardError; end

    class << self
      def default
        new(ENV.fetch("LLM_PROVIDER", default_provider_name))
      end

      def new(provider)
        case provider.to_s
        when "anthropic" then AnthropicAdapter.new
        when "stub"      then StubAdapter.new
        else
          raise Error, "Unknown LLM_PROVIDER=#{provider.inspect}"
        end
      end

      private
        def default_provider_name
          Rails.env.production? ? "anthropic" : "stub"
        end
    end
  end
end
