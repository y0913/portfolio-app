module Messaging
  module Chatwork
    # Renders a platform-neutral OutboundMessage into a ChatWork message body.
    #
    # Output structure:
    #   [rp aid=<sender_id> to=<channel_id>-<message_id>]       # reply marker (if reply_to)
    #   <answer body>
    #
    #   [info][title]参考資料[/title]
    #   [1] <title> (第N節)
    #   <excerpt>
    #   ...
    #   [/info]
    class Formatter
      EXCERPT_LIMIT = 160

      def format(message)
        sections = []
        sections << reply_marker(message.reply_to) if message.reply_to
        sections << message.body.to_s
        sections << citations_block(message.citations) if message.citations.present?
        sections.compact.join("\n").strip
      end

      private
        def reply_marker(reply_to)
          "[rp aid=#{reply_to.sender_id} to=#{reply_to.channel_id}-#{reply_to.message_id}]"
        end

        def citations_block(citations)
          lines = ["[info][title]参考資料[/title]"]
          citations.each do |c|
            number  = c[:number] || c["number"]
            title   = c[:document_title] || c["document_title"]
            pos     = c[:position] || c["position"] || 0
            excerpt = (c[:excerpt] || c["excerpt"]).to_s
            excerpt = excerpt[0, EXCERPT_LIMIT]
            lines << "[#{number}] #{title} (第#{pos + 1}節)"
            lines << excerpt unless excerpt.empty?
          end
          lines << "[/info]"
          lines.join("\n")
        end
    end
  end
end
