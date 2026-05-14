require "faraday"
require "faraday/retry"

module Embedding
  class VoyageAdapter
    API_URL = "https://api.voyageai.com/v1/embeddings".freeze
    MODEL = "voyage-3".freeze
    DIMENSIONS = 1024

    def model_name = MODEL
    def dimensions = DIMENSIONS

    def embed(texts)
      return [] if texts.empty?

      response = connection.post("") do |req|
        req.body = { input: texts, model: MODEL }.to_json
      end

      unless response.success?
        raise Client::Error, "Voyage API error: #{response.status} #{response.body}"
      end

      body = JSON.parse(response.body)
      body.fetch("data").sort_by { _1.fetch("index") }.map { _1.fetch("embedding") }
    end

    private
      def connection
        @connection ||= Faraday.new(url: API_URL) do |f|
          f.request :retry, max: 2, interval: 0.5, backoff_factor: 2,
                    exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed]
          f.headers["Authorization"] = "Bearer #{api_key}"
          f.headers["Content-Type"] = "application/json"
          f.options.timeout = 30
        end
      end

      def api_key
        ENV.fetch("VOYAGE_API_KEY") do
          raise Client::Error, "VOYAGE_API_KEY is not set"
        end
      end
  end
end
