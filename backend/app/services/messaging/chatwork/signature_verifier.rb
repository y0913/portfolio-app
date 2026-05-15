require "openssl"
require "base64"

module Messaging
  module Chatwork
    # Verifies the X-ChatWorkWebhookSignature header on incoming webhook requests.
    #
    # ChatWork computes:  base64( HMAC-SHA256( webhook_token, raw_request_body ) )
    # where `webhook_token` is the secret shown on the webhook settings page.
    #
    # We compare in constant time to avoid leaking via timing.
    class SignatureVerifier
      HEADER = "HTTP_X_CHATWORKWEBHOOKSIGNATURE".freeze

      def initialize(secret: ENV["CHATWORK_WEBHOOK_TOKEN"])
        @secret = secret.to_s
      end

      def configured?
        !@secret.empty?
      end

      def verify(raw_body:, signature:)
        return false unless configured?
        return false if signature.to_s.empty?

        expected = compute(raw_body)
        secure_compare(expected, signature)
      end

      private
        def compute(raw_body)
          digest = OpenSSL::HMAC.digest("sha256", @secret, raw_body.to_s)
          Base64.strict_encode64(digest)
        end

        def secure_compare(a, b)
          return false if a.bytesize != b.bytesize
          ActiveSupport::SecurityUtils.fixed_length_secure_compare(a, b)
        end
    end
  end
end
