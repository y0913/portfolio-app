class ProcessInboundMessageJob < ApplicationJob
  queue_as :default

  # Process a normalized Messaging::InboundMessage (serialized as Hash).
  #
  # Flow:
  #   1. Reconstruct InboundMessage
  #   2. Run RAG (Rag::Answerer) using question = inbound.body
  #   3. Build OutboundMessage (answer text + citations + reply marker)
  #   4. Post back via the matching Messaging::Client adapter
  #
  # Errors:
  #   - On unexpected failure, attempt to post a brief error message back to
  #     the channel so the user is not left hanging, then re-raise so the
  #     queue retries / records the failure.
  def perform(serialized)
    inbound = Messaging::InboundMessage.from_serializable(serialized)
    client  = Messaging::Client.for(inbound.platform)

    result = Rag::Answerer.new.answer(inbound.body)

    outbound = Messaging::OutboundMessage.new(
      body: result.content,
      citations: result.citations,
      reply_to: inbound
    )

    client.post(channel_id: inbound.channel_id, message: outbound)
  rescue StandardError => e
    Rails.logger.error("[ProcessInboundMessageJob] #{e.class}: #{e.message}")
    notify_failure(inbound, client, e) if inbound && client
    raise
  end

  private
    def notify_failure(inbound, client, error)
      fallback = Messaging::OutboundMessage.new(
        body: "申し訳ありません、回答の生成に失敗しました。 (#{error.class})",
        citations: [],
        reply_to: inbound
      )
      client.post(channel_id: inbound.channel_id, message: fallback)
    rescue StandardError => e
      Rails.logger.error("[ProcessInboundMessageJob] failed to notify failure: #{e.class} #{e.message}")
    end
end
