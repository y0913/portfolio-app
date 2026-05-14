import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { ApiError, authApi, chatApi, type Citation } from "./api";

type MockResponseInit = {
  status?: number;
  body?: unknown;
  contentType?: string;
};

function mockJsonResponse({ status = 200, body, contentType = "application/json" }: MockResponseInit = {}) {
  return {
    ok: status >= 200 && status < 300,
    status,
    headers: {
      get: (h: string) => (h.toLowerCase() === "content-type" ? contentType : null),
    },
    json: async () => body ?? {},
  } as unknown as Response;
}

describe("authApi.me", () => {
  const originalFetch = global.fetch;
  beforeEach(() => {
    Object.defineProperty(window, "location", {
      value: { pathname: "/app", assign: vi.fn() },
      writable: true,
    });
  });
  afterEach(() => {
    global.fetch = originalFetch;
    vi.restoreAllMocks();
  });

  it("returns the current user when authenticated", async () => {
    global.fetch = vi.fn().mockResolvedValue(
      mockJsonResponse({ status: 200, body: { id: 1, email_address: "demo@example.com" } })
    ) as unknown as typeof fetch;

    const user = await authApi.me();
    expect(user.email_address).toBe("demo@example.com");
    expect(window.location.assign).not.toHaveBeenCalled();
  });

  it("does NOT redirect on 401 (login flow surfaces it to the form)", async () => {
    global.fetch = vi.fn().mockResolvedValue(
      mockJsonResponse({ status: 401, body: { error: "unauthorized" } })
    ) as unknown as typeof fetch;

    await expect(authApi.me()).rejects.toBeInstanceOf(ApiError);
    expect(window.location.assign).not.toHaveBeenCalled();
  });
});

describe("authApi.login", () => {
  const originalFetch = global.fetch;
  beforeEach(() => {
    Object.defineProperty(window, "location", {
      value: { pathname: "/login", assign: vi.fn() },
      writable: true,
    });
  });
  afterEach(() => {
    global.fetch = originalFetch;
    vi.restoreAllMocks();
  });

  it("does NOT redirect on 401 (wrong password)", async () => {
    global.fetch = vi.fn().mockResolvedValue(mockJsonResponse({ status: 401 })) as unknown as typeof fetch;

    await expect(authApi.login("x@example.com", "wrong")).rejects.toBeInstanceOf(ApiError);
    expect(window.location.assign).not.toHaveBeenCalled();
  });
});

describe("authenticated endpoints (401 → /login redirect)", () => {
  const originalFetch = global.fetch;
  let assign: ReturnType<typeof vi.fn>;

  beforeEach(() => {
    assign = vi.fn();
    Object.defineProperty(window, "location", {
      value: { pathname: "/app/chat", assign },
      writable: true,
    });
  });
  afterEach(() => {
    global.fetch = originalFetch;
    vi.restoreAllMocks();
  });

  it("chatApi.listSessions hard-redirects to /login on 401", async () => {
    global.fetch = vi.fn().mockResolvedValue(mockJsonResponse({ status: 401 })) as unknown as typeof fetch;

    await expect(chatApi.listSessions()).rejects.toBeInstanceOf(ApiError);
    expect(assign).toHaveBeenCalledWith("/login");
  });
});

describe("chatApi.streamMessage SSE parsing", () => {
  const originalFetch = global.fetch;
  afterEach(() => {
    global.fetch = originalFetch;
    vi.restoreAllMocks();
  });

  function bodyFromChunks(chunks: string[]) {
    const encoder = new TextEncoder();
    let i = 0;
    return new ReadableStream<Uint8Array>({
      pull(controller) {
        if (i >= chunks.length) {
          controller.close();
          return;
        }
        controller.enqueue(encoder.encode(chunks[i++]));
      },
    });
  }

  it("parses user_message → citations → delta → done events", async () => {
    const citation: Citation = {
      number: 1,
      document_id: 10,
      document_title: "Doc",
      chunk_id: 100,
      position: 0,
      excerpt: "ex",
      content: "full content",
    };

    const stream = bodyFromChunks([
      'event: user_message\ndata: {"id":1,"role":"user","content":"hi","citations":[],"created_at":"t"}\n\n',
      `event: citations\ndata: ${JSON.stringify([citation])}\n\n`,
      'event: delta\ndata: {"text":"Hel"}\n\n',
      'event: delta\ndata: {"text":"lo"}\n\n',
      'event: done\ndata: {"id":2,"role":"assistant","content":"Hello","citations":[],"created_at":"t"}\n\n',
    ]);

    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      body: stream,
    }) as unknown as typeof fetch;

    const events: string[] = [];
    let collected = "";
    await chatApi.streamMessage(1, "hi", {
      onUserMessage: (m) => events.push(`user_message:${m.content}`),
      onCitations: (cs) => events.push(`citations:${cs.length}`),
      onDelta: (t) => {
        collected += t;
        events.push(`delta:${t}`);
      },
      onDone: (m) => events.push(`done:${m.content}`),
    });

    expect(collected).toBe("Hello");
    expect(events[0]).toBe("user_message:hi");
    expect(events[1]).toBe("citations:1");
    expect(events[events.length - 1]).toBe("done:Hello");
  });

  it("survives an event split across chunks", async () => {
    const stream = bodyFromChunks([
      'event: delta\nda',
      'ta: {"text":"split"}\n\n',
      'event: done\ndata: {"id":1,"role":"assistant","content":"split","citations":[],"created_at":"t"}\n\n',
    ]);

    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      body: stream,
    }) as unknown as typeof fetch;

    let collected = "";
    await chatApi.streamMessage(1, "x", {
      onDelta: (t) => (collected += t),
    });

    expect(collected).toBe("split");
  });
});
