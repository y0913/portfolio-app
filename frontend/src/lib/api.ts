export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:3001";

export type CurrentUser = {
  id: number;
  email_address: string;
  admin: boolean;
};

export class ApiError extends Error {
  status: number;
  body: unknown;

  constructor(status: number, body: unknown, message?: string) {
    super(message ?? `API error ${status}`);
    this.status = status;
    this.body = body;
  }
}

type RequestOptions = {
  // When the server returns 401 for an authenticated endpoint, force a hard
  // navigation to /login so AuthNav and any in-flight state get reset.
  // Endpoints used by the login flow itself (authApi.me / login) should pass
  // skipAuthRedirect: true so they can surface the 401 to their caller.
  skipAuthRedirect?: boolean;
};

function handleUnauthorized() {
  if (typeof window === "undefined") return;
  if (window.location.pathname === "/login") return;
  window.location.assign("/login");
}

async function request<T>(
  path: string,
  init: RequestInit = {},
  opts: RequestOptions = {}
): Promise<T> {
  const res = await fetch(`${API_BASE_URL}${path}`, {
    ...init,
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      ...(init.headers ?? {}),
    },
  });

  const isJson = res.headers.get("content-type")?.includes("application/json");
  const body = isJson ? await res.json().catch(() => null) : null;

  if (!res.ok) {
    if (res.status === 401 && !opts.skipAuthRedirect) {
      handleUnauthorized();
    }
    throw new ApiError(res.status, body);
  }
  return body as T;
}

export const authApi = {
  signup: (email_address: string, password: string) =>
    request<CurrentUser>("/api/users", {
      method: "POST",
      body: JSON.stringify({
        email_address,
        password,
        password_confirmation: password,
      }),
    }),

  login: (email_address: string, password: string) =>
    request<CurrentUser>(
      "/api/session",
      {
        method: "POST",
        body: JSON.stringify({ email_address, password }),
      },
      { skipAuthRedirect: true }
    ),

  logout: () =>
    fetch(`${API_BASE_URL}/api/session`, {
      method: "DELETE",
      credentials: "include",
    }),

  me: () =>
    request<CurrentUser>("/api/session", { method: "GET" }, { skipAuthRedirect: true }),
};

export type DocumentStatus = "pending" | "processing" | "ready" | "failed";

export type DocumentSummary = {
  id: number;
  title: string;
  status: DocumentStatus;
  chunks_count: number;
  filename: string | null;
  byte_size: number | null;
  created_at: string;
  updated_at: string;
};

export const documentsApi = {
  list: () =>
    request<{ documents: DocumentSummary[] }>("/api/documents", { method: "GET" }),

  upload: async (file: File, title?: string): Promise<DocumentSummary> => {
    const form = new FormData();
    form.append("file", file);
    if (title) form.append("title", title);

    const res = await fetch(`${API_BASE_URL}/api/documents`, {
      method: "POST",
      credentials: "include",
      body: form,
    });

    const body = await res.json().catch(() => null);
    if (!res.ok) {
      if (res.status === 401) handleUnauthorized();
      throw new ApiError(res.status, body);
    }
    return body as DocumentSummary;
  },

  destroy: async (id: number): Promise<void> => {
    const res = await fetch(`${API_BASE_URL}/api/documents/${id}`, {
      method: "DELETE",
      credentials: "include",
    });
    if (!res.ok) {
      if (res.status === 401) handleUnauthorized();
      throw new ApiError(res.status, null);
    }
  },
};

export type Citation = {
  number: number;
  document_id: number;
  document_title: string;
  chunk_id: number;
  position: number;
  excerpt: string;
  content: string;
};

export type ChatMessage = {
  id: number;
  role: "user" | "assistant";
  content: string;
  citations: Citation[];
  created_at: string;
};

export type ChatSessionSummary = {
  id: number;
  title: string;
  created_at: string;
  updated_at: string;
  messages_count: number;
};

export type ChatSessionDetail = ChatSessionSummary & {
  messages: ChatMessage[];
};

export const chatApi = {
  listSessions: () =>
    request<{ chat_sessions: ChatSessionSummary[] }>("/api/chat_sessions", { method: "GET" }),

  getSession: (id: number) =>
    request<ChatSessionDetail>(`/api/chat_sessions/${id}`, { method: "GET" }),

  createSession: (title?: string) =>
    request<ChatSessionDetail>("/api/chat_sessions", {
      method: "POST",
      body: JSON.stringify(title ? { title } : {}),
    }),

  destroySession: async (id: number): Promise<void> => {
    const res = await fetch(`${API_BASE_URL}/api/chat_sessions/${id}`, {
      method: "DELETE",
      credentials: "include",
    });
    if (!res.ok) {
      if (res.status === 401) handleUnauthorized();
      throw new ApiError(res.status, null);
    }
  },

  sendMessage: (sessionId: number, content: string) =>
    request<{ user_message: ChatMessage; assistant_message: ChatMessage }>(
      `/api/chat_sessions/${sessionId}/messages`,
      {
        method: "POST",
        body: JSON.stringify({ content }),
      }
    ),

  streamMessage: async (
    sessionId: number,
    content: string,
    handlers: {
      onUserMessage?: (m: ChatMessage) => void;
      onCitations?: (c: Citation[]) => void;
      onDelta?: (text: string) => void;
      onDone?: (m: ChatMessage) => void;
      onError?: (message: string) => void;
      signal?: AbortSignal;
    } = {}
  ): Promise<void> => {
    const res = await fetch(
      `${API_BASE_URL}/api/chat_sessions/${sessionId}/messages/stream`,
      {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json", Accept: "text/event-stream" },
        body: JSON.stringify({ content }),
        signal: handlers.signal,
      }
    );

    if (!res.ok || !res.body) {
      if (res.status === 401) handleUnauthorized();
      throw new ApiError(res.status, null);
    }

    const reader = res.body.getReader();
    const decoder = new TextDecoder("utf-8");
    let buffer = "";

    // eslint-disable-next-line no-constant-condition
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });

      let sepIndex;
      while ((sepIndex = buffer.indexOf("\n\n")) !== -1) {
        const raw = buffer.slice(0, sepIndex);
        buffer = buffer.slice(sepIndex + 2);

        let event = "message";
        let data = "";
        for (const line of raw.split("\n")) {
          if (line.startsWith("event:")) event = line.slice(6).trim();
          else if (line.startsWith("data:")) data += line.slice(5).trimStart();
        }
        if (!data) continue;

        let parsed: unknown;
        try {
          parsed = JSON.parse(data);
        } catch {
          continue;
        }

        switch (event) {
          case "user_message":
            handlers.onUserMessage?.(parsed as ChatMessage);
            break;
          case "citations":
            handlers.onCitations?.(parsed as Citation[]);
            break;
          case "delta":
            handlers.onDelta?.((parsed as { text: string }).text);
            break;
          case "done":
            handlers.onDone?.(parsed as ChatMessage);
            break;
          case "error":
            handlers.onError?.((parsed as { message: string }).message);
            break;
        }
      }
    }
  },
};
