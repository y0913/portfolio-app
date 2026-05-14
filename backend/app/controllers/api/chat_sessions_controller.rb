module Api
  class ChatSessionsController < ApplicationController
    def index
      sessions = Current.user.chat_sessions.order(updated_at: :desc).map { serialize_summary(_1) }
      render json: { chat_sessions: sessions }
    end

    def show
      session = Current.user.chat_sessions.find(params[:id])
      render json: serialize_detail(session)
    end

    def create
      title = params[:title].presence || default_title
      session = Current.user.chat_sessions.create!(title: title)
      render json: serialize_detail(session), status: :created
    end

    def destroy
      session = Current.user.chat_sessions.find(params[:id])
      session.destroy!
      head :no_content
    end

    private
      def default_title
        "#{Time.current.strftime('%m/%d %H:%M')} の質問"
      end

      def serialize_summary(session)
        {
          id: session.id,
          title: session.title,
          created_at: session.created_at,
          updated_at: session.updated_at,
          messages_count: session.messages.count
        }
      end

      def serialize_detail(session)
        serialize_summary(session).merge(
          messages: session.messages.map { |m| serialize_message(m) }
        )
      end

      def serialize_message(message)
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
