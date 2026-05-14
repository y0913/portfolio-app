module Api
  class MessagesController < ApplicationController
    def create
      session = Current.user.chat_sessions.find(params[:chat_session_id])
      content = params[:content].to_s.strip

      if content.blank?
        return render json: { error: "content is required" }, status: :unprocessable_entity
      end

      user_message = session.messages.create!(role: "user", content: content)

      history = session.messages.where.not(id: user_message.id).map do |m|
        { role: m.role, content: m.content }
      end

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

    private
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
