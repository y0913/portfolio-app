module Api
  module Webhooks
    # Inbound webhook from ChatWork.
    #
    # ChatWork sends:
    #   POST /api/webhooks/chatwork
    #   X-ChatWorkWebhookSignature: <base64 HMAC-SHA256>
    #   Content-Type: application/json
    #   body: { webhook_event_type, webhook_event: {...} }
    #
    # We:
    #   1. Verify the signature against raw request body
    #   2. Parse into a normalized Messaging::InboundMessage
    #   3. Drop self-posts (bot replying to itself loop)
    #   4. Enqueue ProcessInboundMessageJob
    #   5. Return 200 quickly (ChatWork retries on non-2xx)
    class ChatworkController < ApplicationController
      # Webhooks are authenticated by signature, not user session.
      allow_unauthenticated_access only: :create

      # CSRF is irrelevant for an API server (no cookies), but make it explicit.
      # ApplicationController inherits from ActionController::API so this is a no-op,
      # kept here as a marker.

      def create
        raw_body = request.raw_post
        signature = request.headers["X-ChatWorkWebhookSignature"]

        verifier = Messaging::Chatwork::SignatureVerifier.new
        unless verifier.configured?
          Rails.logger.error("[chatwork webhook] CHATWORK_WEBHOOK_TOKEN not configured")
          return render json: { error: "webhook not configured" }, status: :service_unavailable
        end

        unless verifier.verify(raw_body: raw_body, signature: signature)
          Rails.logger.warn("[chatwork webhook] invalid signature")
          return render json: { error: "invalid signature" }, status: :unauthorized
        end

        payload = JSON.parse(raw_body)
        inbound = Messaging::Chatwork::PayloadParser.new.parse(payload)

        if bot_self_post?(inbound)
          Rails.logger.info("[chatwork webhook] ignoring self-post from bot account_id=#{inbound.sender_id}")
          return render json: { status: "ignored" }, status: :ok
        end

        if inbound.body.blank?
          return render json: { status: "ignored", reason: "empty body" }, status: :ok
        end

        ProcessInboundMessageJob.perform_later(inbound.to_h_serializable)

        render json: { status: "queued" }, status: :ok
      rescue JSON::ParserError => e
        Rails.logger.warn("[chatwork webhook] invalid JSON: #{e.message}")
        render json: { error: "invalid json" }, status: :bad_request
      rescue Messaging::Chatwork::PayloadParser::ParseError => e
        Rails.logger.warn("[chatwork webhook] parse error: #{e.message}")
        # Return 200 so ChatWork does not retry — the payload shape is wrong,
        # retrying will not help.
        render json: { status: "ignored", reason: e.message }, status: :ok
      end

      private
        def bot_self_post?(inbound)
          bot_id = ENV["CHATWORK_BOT_ACCOUNT_ID"].to_s
          !bot_id.empty? && inbound.sender_id == bot_id
        end
    end
  end
end
