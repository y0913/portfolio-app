module Messaging
  # Factory + abstract interface for messaging platform adapters.
  #
  # Concrete adapters must implement:
  #   #platform                          -> Symbol
  #   #post(channel_id:, message:)       -> Hash (response body)
  #     where `message` is an OutboundMessage
  #
  # Each platform also provides a SignatureVerifier and a PayloadParser used by
  # its webhook controller, but those are not part of the Client interface
  # because their inputs (raw request body, headers) are HTTP-specific.
  #
  # Add a new platform:
  #   1. Create Messaging::<Platform>::{Client,SignatureVerifier,PayloadParser,Formatter}
  #   2. Register it in the `case` below
  #   3. Add a controller at Api::Webhooks::<Platform>Controller and route
  module Client
    class Error < StandardError; end
    class ConfigurationError < Error; end

    class << self
      # Resolve adapter by platform symbol/string.
      def for(platform)
        case platform.to_s
        when "chatwork" then Chatwork::Client.new
        else
          raise Error, "Unknown messaging platform: #{platform.inspect}"
        end
      end
    end
  end
end
