require "faraday"
require "faraday/retry"

module Messaging
  module Chatwork
    # Posts messages to ChatWork via the v2 REST API.
    #
    # Auth:  X-ChatWorkToken: <CHATWORK_API_TOKEN>
    # Docs:  https://developer.chatwork.com/reference/post-rooms-room_id-messages
    class Client
      API_BASE = "https://api.chatwork.com/v2".freeze

      def platform = :chatwork

      def initialize(api_token: ENV["CHATWORK_API_TOKEN"], formatter: Formatter.new)
        @api_token = api_token.to_s
        @formatter = formatter
      end

      def post(channel_id:, message:)
        body = @formatter.format(message)
        post_text(channel_id: channel_id, body: body)
      end

      # Low-level escape hatch (e.g. for error notifications). Use #post normally.
      def post_text(channel_id:, body:)
        raise Messaging::Client::ConfigurationError, "CHATWORK_API_TOKEN is not set" if @api_token.empty?

        response = connection.post("rooms/#{channel_id}/messages") do |req|
          req.body = URI.encode_www_form(body: body, self_unread: 0)
        end

        unless response.success?
          raise Messaging::Client::Error,
                "ChatWork API error: #{response.status} #{response.body}"
        end

        JSON.parse(response.body)
      end

      private
        def connection
          @connection ||= Faraday.new(url: API_BASE) do |f|
            f.request :retry, max: 2, interval: 0.5, backoff_factor: 2,
                      exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed]
            f.headers["X-ChatWorkToken"] = @api_token
            f.headers["Content-Type"] = "application/x-www-form-urlencoded"
            f.options.timeout = 15
          end
        end
    end
  end
end
