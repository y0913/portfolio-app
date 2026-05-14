module Rag
  # Orchestrates a RAG round trip: retrieve chunks, build prompt, call LLM,
  # return answer text + citation array.
  class Answerer
    Result = Struct.new(:content, :citations, :chunks, keyword_init: true)

    SYSTEM_PROMPT = <<~SYS.freeze
      あなたはユーザーが提供した社内ドキュメントに基づいて質問に答えるアシスタントです。

      ルール:
      - 必ず以下の「資料」に書かれている内容だけを根拠に回答してください。資料にない事柄は推測しないでください。
      - 回答の各文や根拠の直後に [1] [2] のように番号で資料を引用してください。番号は与えられた資料の番号と対応します。
      - 資料に答えがない場合は「資料からは確認できません」と素直に伝えてください。
      - 回答は日本語で、簡潔に書いてください。
    SYS

    def initialize(user:, retriever: Retriever.new(user: user), llm: Llm::Client.default)
      @user = user
      @retriever = retriever
      @llm = llm
    end

    def answer(question, history: [])
      chunks, citations, messages = prepare(question, history)
      content = @llm.generate(messages, system: SYSTEM_PROMPT, max_tokens: 1024, temperature: 0.2)

      Result.new(content: content, citations: citations, chunks: chunks)
    end

    # Streaming variant. Yields (event_type, payload) tuples:
    #   [:citations, Array<Hash>] — fired once before the first token
    #   [:delta, String]          — text fragments as they arrive
    #   [:done, String]           — final concatenated answer (also returned)
    def stream_answer(question, history: [])
      chunks, citations, messages = prepare(question, history)
      yield :citations, citations

      buffer = +""
      @llm.generate_stream(messages, system: SYSTEM_PROMPT, max_tokens: 1024, temperature: 0.2) do |delta|
        buffer << delta
        yield :delta, delta
      end

      yield :done, buffer
      Result.new(content: buffer, citations: citations, chunks: chunks)
    end

    private
      def prepare(question, history)
        chunks = @retriever.search(question)
        citations = chunks.each_with_index.map { |c, i| build_citation(c, i + 1) }
        context = build_context(chunks)

        messages = history.map { |m| { role: m.fetch(:role), content: m.fetch(:content) } }
        messages << {
          role: "user",
          content: <<~MSG.strip
            # 資料
            #{context.presence || "(該当する資料は見つかりませんでした)"}

            # 質問
            #{question}
          MSG
        }
        [chunks, citations, messages]
      end

      def build_context(chunks)
        chunks.each_with_index.map do |c, i|
          "[#{i + 1}] (#{c.document.title}, 第#{c.position + 1}節)\n#{c.content}"
        end.join("\n\n")
      end

      def build_citation(chunk, number)
        {
          number: number,
          document_id: chunk.document_id,
          document_title: chunk.document.title,
          chunk_id: chunk.id,
          position: chunk.position,
          excerpt: chunk.content.to_s[0, 160],
          content: chunk.content.to_s
        }
      end
  end
end
