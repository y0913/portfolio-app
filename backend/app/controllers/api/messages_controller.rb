module Api
  class MessagesController < ApplicationController
    include ActionController::Live

    def create
      session = Current.user.chat_sessions.find(params[:chat_session_id])
      content = params[:content].to_s.strip

      if content.blank?
        return render json: { error: "content is required" }, status: :unprocessable_entity
      end

      user_message = session.messages.create!(role: "user", content: content)
      history = history_excluding(session, user_message)

      result = Rag::Answerer.new(user: Current.user).answer(content, history: history)

      assistant_message = session.messages.create!(
        role: "assistant",
        content: result.content,
        citations: result.citations
      )

      session.touch

      render json: {
        user_message: serialize(user_message),
        assistant_message: serialize(assistant_message)
      }, status: :created
    end

    # Streaming variant. Emits Server-Sent Events:
    #   event: user_message  | data: <user message json>
    #   event: citations     | data: <citations array>
    #   event: delta         | data: { "text": "..." }
    #   event: done          | data: <full assistant message json>
    #   event: error         | data: { "message": "..." }
    def stream
      session = Current.user.chat_sessions.find(params[:chat_session_id])
      content = params[:content].to_s.strip

      response.headers["Content-Type"] = "text/event-stream"
      response.headers["Cache-Control"] = "no-cache"
      response.headers["X-Accel-Buffering"] = "no" # disable nginx buffering if proxied

      sse = SSE.new(response.stream)

      if content.blank?
        sse.write({ message: "content is required" }, event: "error")
        return
      end

      user_message = session.messages.create!(role: "user", content: content)
      sse.write(serialize(user_message), event: "user_message")

      history = history_excluding(session, user_message)
      answerer = Rag::Answerer.new(user: Current.user)
      citations_payload = nil

      result = answerer.stream_answer(content, history: history) do |event_type, payload|
        case event_type
        when :citations
          citations_payload = payload
          sse.write(payload, event: "citations")
        when :delta
          sse.write({ text: payload }, event: "delta")
        when :done
          # handled after the block
        end
      end

      assistant_message = session.messages.create!(
        role: "assistant",
        content: result.content,
        citations: citations_payload || []
      )
      session.touch

      sse.write(serialize(assistant_message), event: "done")
    rescue ActiveRecord::RecordNotFound
      sse&.write({ message: "not_found" }, event: "error")
    rescue StandardError => e
      Rails.logger.error("stream error: #{e.class} #{e.message}")
      sse&.write({ message: e.message }, event: "error")
    ensure
      sse&.close
    end

    private
      def history_excluding(session, message)
        session.messages.where.not(id: message.id).map do |m|
          { role: m.role, content: m.content }
        end
      end

      def serialize(message)
        {
          id: message.id,
          role: message.role,
          content: message.content,
          citations: message.citations,
          created_at: message.created_at
        }
      end
  end
end

# Lightweight Server-Sent Events writer (JSON-serialized payloads).
class SSE
  def initialize(io)
    @io = io
  end

  def write(payload, event:)
    @io.write("event: #{event}\n")
    @io.write("data: #{payload.to_json}\n\n")
  end

  def close
    @io.close
  rescue IOError
    # already closed
  end
end

