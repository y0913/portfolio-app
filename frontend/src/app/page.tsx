type HelloResponse = {
  message: string;
  time: string;
};

async function getHello(): Promise<HelloResponse | null> {
  const base = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:3001";
  try {
    const res = await fetch(`${base}/api/hello`, { cache: "no-store" });
    if (!res.ok) return null;
    return (await res.json()) as HelloResponse;
  } catch {
    return null;
  }
}

export default async function Home() {
  const hello = await getHello();

  return (
    <main className="min-h-screen flex flex-col items-center justify-center gap-6 p-8 font-sans">
      <h1 className="text-3xl font-bold">Portfolio App</h1>
      <p className="text-zinc-600 dark:text-zinc-400">
        Next.js frontend × Rails API backend
      </p>
      <section className="rounded-lg border border-zinc-200 dark:border-zinc-800 p-6 min-w-[320px]">
        <h2 className="text-lg font-semibold mb-2">API Response</h2>
        {hello ? (
          <dl className="grid grid-cols-[auto_1fr] gap-x-4 gap-y-1 text-sm">
            <dt className="text-zinc-500">message</dt>
            <dd>{hello.message}</dd>
            <dt className="text-zinc-500">time</dt>
            <dd>{hello.time}</dd>
          </dl>
        ) : (
          <p className="text-red-600 text-sm">
            Failed to reach Rails API. Make sure backend is running on{" "}
            <code>http://localhost:3001</code>.
          </p>
        )}
      </section>
    </main>
  );
}
