module Llm
  # Returns canned text for local development without API keys.
  class StubAdapter
    MODEL = "stub-llm".freeze

    def model_name = MODEL

    def generate(messages, **_opts)
      last_user = messages.reverse.find { _1[:role] == "user" }&.fetch(:content, "")
      "[stub LLM] received: #{last_user.to_s[0, 200]}"
    end
  end
end
