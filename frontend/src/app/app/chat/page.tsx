"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  Loader2,
  MessageSquarePlus,
  SendHorizontal,
  Trash2,
} from "lucide-react";

import { Button, buttonVariants } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import {
  ApiError,
  chatApi,
  type ChatMessage,
  type ChatSessionDetail,
  type ChatSessionSummary,
  type Citation,
} from "@/lib/api";
import { cn } from "@/lib/utils";

function CitationBadges({ citations }: { citations: Citation[] }) {
  if (!citations.length) return null;
  return (
    <div className="mt-3 flex flex-wrap gap-1.5">
      {citations.map((c) => (
        <span
          key={c.chunk_id}
          title={c.excerpt}
          className="inline-flex items-center gap-1 rounded-md border bg-background/60 px-1.5 py-0.5 text-[11px] text-muted-foreground"
        >
          <span className="font-mono">[{c.number}]</span>
          <span className="max-w-[14rem] truncate">{c.document_title}</span>
        </span>
      ))}
    </div>
  );
}

function MessageBubble({ message }: { message: ChatMessage }) {
  const isUser = message.role === "user";
  return (
    <div className={cn("flex", isUser ? "justify-end" : "justify-start")}>
      <div
        className={cn(
          "max-w-[85%] whitespace-pre-wrap rounded-2xl px-4 py-2.5 text-sm leading-relaxed",
          isUser
            ? "bg-primary text-primary-foreground"
            : "border bg-muted/30 text-foreground"
        )}
      >
        {message.content}
        {!isUser && <CitationBadges citations={message.citations} />}
      </div>
    </div>
  );
}

export default function ChatPage() {
  const [sessions, setSessions] = useState<ChatSessionSummary[] | null>(null);
  const [active, setActive] = useState<ChatSessionDetail | null>(null);
  const [activeId, setActiveId] = useState<number | null>(null);
  const [input, setInput] = useState("");
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const scrollRef = useRef<HTMLDivElement | null>(null);

  const refreshSessions = useCallback(async () => {
    try {
      const { chat_sessions } = await chatApi.listSessions();
      setSessions(chat_sessions);
      if (activeId == null && chat_sessions.length > 0) {
        setActiveId(chat_sessions[0].id);
      }
    } catch {
      setSessions([]);
    }
  }, [activeId]);

  useEffect(() => {
    refreshSessions();
  }, [refreshSessions]);

  useEffect(() => {
    if (activeId == null) {
      setActive(null);
      return;
    }
    let alive = true;
    chatApi
      .getSession(activeId)
      .then((s) => {
        if (alive) setActive(s);
      })
      .catch(() => {
        if (alive) setActive(null);
      });
    return () => {
      alive = false;
    };
  }, [activeId]);

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: "smooth" });
  }, [active?.messages.length, sending]);

  async function onNewSession() {
    setError(null);
    try {
      const created = await chatApi.createSession();
      setActive(created);
      setActiveId(created.id);
      await refreshSessions();
    } catch {
      setError("セッションの作成に失敗しました。");
    }
  }

  async function onDeleteSession(id: number) {
    if (!confirm("このセッションを削除しますか？")) return;
    try {
      await chatApi.destroySession(id);
      if (activeId === id) {
        setActiveId(null);
        setActive(null);
      }
      await refreshSessions();
    } catch {
      setError("削除に失敗しました。");
    }
  }

  async function onSend() {
    const content = input.trim();
    if (!content || sending) return;
    setError(null);

    let sessionId = activeId;
    if (sessionId == null) {
      try {
        const created = await chatApi.createSession();
        sessionId = created.id;
        setActive(created);
        setActiveId(created.id);
        await refreshSessions();
      } catch {
        setError("セッションの作成に失敗しました。");
        return;
      }
    }

    setInput("");
    setSending(true);

    // Placeholder assistant message that we will fill in as deltas arrive.
    const placeholderId = -Date.now();
    const placeholder: ChatMessage = {
      id: placeholderId,
      role: "assistant",
      content: "",
      citations: [],
      created_at: new Date().toISOString(),
    };

    try {
      await chatApi.streamMessage(sessionId, content, {
        onUserMessage: (m) => {
          setActive((s) => (s ? { ...s, messages: [...s.messages, m, placeholder] } : s));
        },
        onCitations: (citations) => {
          setActive((s) => {
            if (!s) return s;
            const messages = s.messages.map((m) =>
              m.id === placeholderId ? { ...m, citations } : m
            );
            return { ...s, messages };
          });
        },
        onDelta: (text) => {
          setActive((s) => {
            if (!s) return s;
            const messages = s.messages.map((m) =>
              m.id === placeholderId ? { ...m, content: m.content + text } : m
            );
            return { ...s, messages };
          });
        },
        onDone: (final) => {
          setActive((s) => {
            if (!s) return s;
            const messages = s.messages.map((m) =>
              m.id === placeholderId ? final : m
            );
            return { ...s, messages };
          });
        },
        onError: (msg) => {
          setError(msg);
        },
      });
      await refreshSessions();
    } catch (err) {
      if (err instanceof ApiError) {
        const body = err.body as { error?: string } | null;
        setError(body?.error ?? "送信に失敗しました。");
      } else {
        setError("送信に失敗しました。");
      }
      // Roll back the placeholder if the stream never finished.
      setActive((s) => {
        if (!s) return s;
        return { ...s, messages: s.messages.filter((m) => m.id !== placeholderId) };
      });
    } finally {
      setSending(false);
    }
  }

  function onKeyDown(e: React.KeyboardEvent<HTMLTextAreaElement>) {
    if (e.key === "Enter" && (e.metaKey || e.ctrlKey)) {
      e.preventDefault();
      onSend();
    }
  }

  const isEmpty = useMemo(
    () => active == null || active.messages.length === 0,
    [active]
  );

  return (
    <div className="container mx-auto grid h-[calc(100vh-7rem)] max-w-5xl grid-cols-1 gap-6 px-4 py-6 md:grid-cols-[16rem_1fr]">
      <aside className="flex min-h-0 flex-col gap-3 md:border-r md:pr-4">
        <Button onClick={onNewSession} size="sm" variant="outline" className="justify-start">
          <MessageSquarePlus className="mr-1.5 h-4 w-4" />
          新しい質問
        </Button>
        <div className="min-h-0 flex-1 overflow-y-auto">
          {sessions == null ? (
            <p className="text-xs text-muted-foreground">読み込み中...</p>
          ) : sessions.length === 0 ? (
            <p className="text-xs text-muted-foreground">セッションはありません</p>
          ) : (
            <ul className="space-y-1">
              {sessions.map((s) => (
                <li key={s.id}>
                  <div
                    className={cn(
                      "group flex items-center justify-between gap-1 rounded-md px-2 py-1.5 text-xs",
                      activeId === s.id
                        ? "bg-muted text-foreground"
                        : "text-muted-foreground hover:bg-muted/50"
                    )}
                  >
                    <button
                      type="button"
                      onClick={() => setActiveId(s.id)}
                      className="min-w-0 flex-1 truncate text-left"
                    >
                      {s.title}
                    </button>
                    <button
                      type="button"
                      onClick={() => onDeleteSession(s.id)}
                      className="opacity-0 transition-opacity group-hover:opacity-100 hover:text-destructive"
                      aria-label="削除"
                    >
                      <Trash2 className="h-3 w-3" />
                    </button>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </div>
      </aside>

      <section className="flex min-h-0 flex-col">
        <div ref={scrollRef} className="flex-1 overflow-y-auto pr-1">
          {isEmpty ? (
            <div className="flex h-full flex-col items-center justify-center text-center text-sm text-muted-foreground">
              <p className="font-medium text-foreground">資料に質問してみましょう</p>
              <p className="mt-1 max-w-sm">
                取り込んだドキュメントの内容に基づいて、根拠 (引用) 付きで回答します。
              </p>
              <a
                href="/app/documents"
                className={cn(
                  buttonVariants({ variant: "outline", size: "sm" }),
                  "mt-3"
                )}
              >
                資料を確認する
              </a>
            </div>
          ) : (
            <div className="space-y-3">
              {active!.messages.map((m) => (
                <MessageBubble key={m.id} message={m} />
              ))}
              {sending && (
                <div className="flex justify-start">
                  <div className="flex items-center gap-2 rounded-2xl border bg-muted/30 px-4 py-2.5 text-sm text-muted-foreground">
                    <Loader2 className="h-3.5 w-3.5 animate-spin" />
                    回答を生成中...
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        {error && (
          <p className="mt-2 rounded-md border border-destructive/30 bg-destructive/5 px-3 py-2 text-xs text-destructive">
            {error}
          </p>
        )}

        <div className="mt-3 flex items-end gap-2 border-t pt-3">
          <Textarea
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={onKeyDown}
            placeholder="資料について質問する... (Cmd/Ctrl + Enter で送信)"
            rows={2}
            className="flex-1 resize-none"
            disabled={sending}
          />
          <Button onClick={onSend} disabled={sending || !input.trim()} className="shrink-0">
            <SendHorizontal className="mr-1 h-4 w-4" />
            送信
          </Button>
        </div>
      </section>
    </div>
  );
}
