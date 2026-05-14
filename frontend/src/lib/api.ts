export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:3001";

export type CurrentUser = {
  id: number;
  email_address: string;
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

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
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
    request<CurrentUser>("/api/session", {
      method: "POST",
      body: JSON.stringify({ email_address, password }),
    }),

  logout: () =>
    fetch(`${API_BASE_URL}/api/session`, {
      method: "DELETE",
      credentials: "include",
    }),

  me: () => request<CurrentUser>("/api/session", { method: "GET" }),
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
      throw new ApiError(res.status, null);
    }
  },
};
