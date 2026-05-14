module Llm
  # Returns canned text for local development without API keys.
  class StubAdapter
    MODEL = "stub-llm".freeze

    def model_name = MODEL

    def generate(messages, **_opts)
      canned_text(messages)
    end

    def generate_stream(messages, **_opts)
      text = canned_text(messages)
      # Emit a few characters at a time so the UI can demonstrate streaming.
      text.each_char.each_slice(3) do |chunk|
        yield chunk.join
        sleep 0.02
      end
    end

    private
      def canned_text(messages)
        last_user = messages.reverse.find { _1[:role] == "user" }&.fetch(:content, "")
        "[stub LLM] received: #{last_user.to_s[0, 200]}"
      end
  end
end
