module Messaging
  module Chatwork
    # Converts a ChatWork webhook payload into a Messaging::InboundMessage.
    #
    # Expected webhook event types (`webhook_event_type`):
    #   - "message_created"   - new message in a room
    #   - "mention_to_me"     - user mentioned the bot
    # We accept both and treat them uniformly.
    #
    # Example payload (message_created):
    #   {
    #     "webhook_setting_id": "...",
    #     "webhook_event_type": "message_created",
    #     "webhook_event_time": 1700000000,
    #     "webhook_event": {
    #       "message_id":  "12345",
    #       "room_id":     67890,
    #       "account_id":  111,
    #       "body":        "[To:222] 質問内容",
    #       "send_time":   1700000000,
    #       "update_time": 0
    #     }
    #   }
    class PayloadParser
      SUPPORTED_EVENT_TYPES = %w[message_created mention_to_me].freeze

      ParseError = Class.new(StandardError)

      def parse(payload)
        unless payload.is_a?(Hash)
          raise ParseError, "payload must be a Hash, got #{payload.class}"
        end

        event_type = payload["webhook_event_type"].to_s
        unless SUPPORTED_EVENT_TYPES.include?(event_type)
          raise ParseError, "unsupported webhook_event_type: #{event_type.inspect}"
        end

        event = payload["webhook_event"]
        raise ParseError, "webhook_event missing" unless event.is_a?(Hash)

        room_id    = event["room_id"]
        account_id = event["account_id"]
        message_id = event["message_id"]
        body       = event["body"].to_s

        if room_id.nil? || account_id.nil? || message_id.nil?
          raise ParseError, "webhook_event is missing required fields"
        end

        InboundMessage.new(
          platform:    :chatwork,
          channel_id:  room_id.to_s,
          sender_id:   account_id.to_s,
          sender_name: nil, # ChatWork webhook does not include display name
          body:        strip_chatwork_tags(body),
          message_id:  message_id.to_s,
          raw:         payload
        )
      end

      private
        # Remove ChatWork-specific reply/mention tags so the LLM gets clean text.
        #   [To:222]              -> ""   (mention)
        #   [rp aid=222 to=33-44] -> ""   (reply marker)
        #   [reply aid=...]       -> ""   (reply marker, legacy)
        #   [qt][qtmeta ...][/qt] -> ""   (quote)
        #   [info]...[/info]      -> kept (might be useful context)
        def strip_chatwork_tags(body)
          body.gsub(/\[(?:To:|rp\s|reply\s)[^\]]+\]/i, "")
              .gsub(/\[qt\].*?\[\/qt\]/im, "")
              .strip
        end
    end
  end
end
