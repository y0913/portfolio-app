module Messaging
  # Platform-neutral outbound message. Each adapter's Formatter turns this
  # into the actual body string that platform expects (ChatWork [info] tags,
  # Slack blocks, Discord embeds, ...).
  #
  # Fields:
  #   body       - String. Main answer text from the LLM.
  #   citations  - Array<Hash>. RAG citation entries (see Rag::Answerer#build_citation).
  #                May be empty.
  #   reply_to   - InboundMessage, optional. When present, formatter can render
  #                a platform-specific reply marker (e.g. ChatWork [rp]).
  OutboundMessage = Struct.new(:body, :citations, :reply_to, keyword_init: true) do
    def initialize(*)
      super
      self.citations ||= []
    end
  end
end
