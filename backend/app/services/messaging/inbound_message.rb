module Messaging
  # Normalized representation of an inbound chat message from any platform
  # (ChatWork / Slack / Discord / ...). Adapters convert their webhook payload
  # into this struct so downstream code (jobs, RAG) is platform-agnostic.
  #
  # Fields:
  #   platform        - Symbol like :chatwork, :slack
  #   channel_id      - String. Room/channel identifier on the source platform.
  #   sender_id       - String. The user who sent the message (used to skip bot's own posts).
  #   sender_name     - String, optional. Display name if available.
  #   body            - String. Plain-text body (mentions stripped if applicable).
  #   message_id      - String. Source message ID (used for reply threading).
  #   raw             - Hash. Original payload (for debugging / future use).
  InboundMessage = Struct.new(
    :platform, :channel_id, :sender_id, :sender_name,
    :body, :message_id, :raw,
    keyword_init: true
  ) do
    def to_h_serializable
      {
        "platform" => platform.to_s,
        "channel_id" => channel_id,
        "sender_id" => sender_id,
        "sender_name" => sender_name,
        "body" => body,
        "message_id" => message_id,
        "raw" => raw
      }
    end

    def self.from_serializable(hash)
      new(
        platform: hash["platform"].to_sym,
        channel_id: hash["channel_id"],
        sender_id: hash["sender_id"],
        sender_name: hash["sender_name"],
        body: hash["body"],
        message_id: hash["message_id"],
        raw: hash["raw"]
      )
    end
  end
end
