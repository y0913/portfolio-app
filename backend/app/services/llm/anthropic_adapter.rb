require "faraday"
require "faraday/retry"

module Llm
  class AnthropicAdapter
    API_URL = "https://api.anthropic.com/v1/messages".freeze
    DEFAULT_MODEL = "claude-sonnet-4-6".freeze
    API_VERSION = "2023-06-01".freeze

    def model_name = ENV.fetch("ANTHROPIC_MODEL", DEFAULT_MODEL)

    def generate(messages, max_tokens: 1024, temperature: 0.2, system: nil)
      payload = {
        model: model_name,
        max_tokens: max_tokens,
        temperature: temperature,
        messages: messages.map { |m| { role: m.fetch(:role), content: m.fetch(:content) } }
      }
      payload[:system] = system if system

      response = connection.post("") { |req| req.body = payload.to_json }

      unless response.success?
        raise Client::Error, "Anthropic API error: #{response.status} #{response.body}"
      end

      body = JSON.parse(response.body)
      body.fetch("content").map { _1.fetch("text") }.join
    end

    private
      def connection
        @connection ||= Faraday.new(url: API_URL) do |f|
          f.request :retry, max: 2, interval: 0.5, backoff_factor: 2,
                    exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed]
          f.headers["x-api-key"] = api_key
          f.headers["anthropic-version"] = API_VERSION
          f.headers["Content-Type"] = "application/json"
          f.options.timeout = 60
        end
      end

      def api_key
        ENV.fetch("ANTHROPIC_API_KEY") do
          raise Client::Error, "ANTHROPIC_API_KEY is not set"
        end
      end
  end
end
