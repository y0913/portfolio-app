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
