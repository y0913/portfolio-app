import Link from "next/link";
import {
  ArrowRight,
  FileText,
  MessagesSquare,
  Quote,
} from "lucide-react";

import { buttonVariants } from "@/components/ui/button";
import {
  Card,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

type HelloResponse = {
  message: string;
  time: string;
};

async function getApiStatus(): Promise<HelloResponse | null> {
  const base = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:3001";
  try {
    const res = await fetch(`${base}/api/hello`, { cache: "no-store" });
    if (!res.ok) return null;
    return (await res.json()) as HelloResponse;
  } catch {
    return null;
  }
}

const steps = [
  {
    icon: FileText,
    title: "資料をアップロードする",
    description:
      "マニュアル・議事録・社内規定など、PDFやテキストを投げ込むだけ。AIが中身を読み込んで質問に答えられる状態に整えます。",
  },
  {
    icon: MessagesSquare,
    title: "知りたいことを質問する",
    description:
      "「返金ポリシーは？」「○○の手順を教えて」 ── ふだん人に聞くように、自然な日本語で質問できます。",
  },
  {
    icon: Quote,
    title: "出典付きで答えが返る",
    description:
      "回答には「どの資料の、どの段落から引用したか」が必ず付きます。AIの答えを鵜呑みにせず、自分の目で確かめられます。",
  },
];

export default async function Home() {
  const status = await getApiStatus();

  return (
    <div className="container mx-auto max-w-5xl px-4 py-16 sm:py-24">
      <section className="flex flex-col items-center text-center gap-6">
        <span className="inline-flex items-center gap-1.5 rounded-full border bg-muted/40 px-3 py-1 text-xs font-medium text-muted-foreground">
          <span className="size-1.5 rounded-full bg-emerald-500" />
          Live demo
        </span>
        <h1 className="text-4xl font-bold tracking-tight sm:text-5xl">
          社内の資料を、
          <br className="sm:hidden" />
          AIに聞いて引き出す。
        </h1>
        <p className="max-w-2xl text-base text-muted-foreground sm:text-lg">
          マニュアル、議事録、規約 ── 探すのに時間がかかる社内ドキュメントを
          AI が読み込んで、質問に答えてくれます。回答には必ず出典が付くので、
          根拠を確認しながら使えます。
        </p>
        <div className="flex flex-col gap-3 sm:flex-row">
          <Link href="/login" className={buttonVariants({ size: "lg" })}>
            デモを試す
            <ArrowRight className="ml-1 h-4 w-4" />
          </Link>
          <Link
            href="#how-it-works"
            className={buttonVariants({ variant: "outline", size: "lg" })}
          >
            使い方を見る
          </Link>
        </div>
      </section>

      <section id="how-it-works" className="mt-24 scroll-mt-20">
        <div className="mb-10 text-center">
          <p className="text-xs font-medium uppercase tracking-wider text-muted-foreground">
            How it works
          </p>
          <h2 className="mt-2 text-2xl font-semibold tracking-tight sm:text-3xl">
            3 ステップで使えます
          </h2>
        </div>
        <div className="grid gap-4 sm:grid-cols-3">
          {steps.map((s, i) => (
            <Card key={s.title} className="border-border/60">
              <CardHeader>
                <div className="flex items-center justify-between">
                  <s.icon className="h-5 w-5 text-muted-foreground" />
                  <span className="text-xs font-mono text-muted-foreground">
                    0{i + 1}
                  </span>
                </div>
                <CardTitle className="text-base">{s.title}</CardTitle>
                <CardDescription className="leading-relaxed">
                  {s.description}
                </CardDescription>
              </CardHeader>
            </Card>
          ))}
        </div>
      </section>

      <section className="mt-24 rounded-xl border bg-muted/30 p-6 sm:p-8">
        <p className="text-sm leading-relaxed text-muted-foreground">
          合同会社Build による技術検証プロジェクトです。ソースコードは{" "}
          <a
            href="https://github.com/y0913/portfolio-app"
            target="_blank"
            rel="noopener noreferrer"
            className="font-medium text-foreground underline-offset-4 hover:underline"
          >
            GitHub
          </a>
          で公開しています。
        </p>
        <details className="mt-4 group">
          <summary className="cursor-pointer text-sm font-medium text-foreground/70 hover:text-foreground select-none">
            技術スタック
          </summary>
          <ul className="mt-3 grid gap-1 text-sm text-muted-foreground sm:grid-cols-2">
            <li>• Next.js 16 / React 19 / TypeScript</li>
            <li>• Tailwind CSS / shadcn/ui</li>
            <li>• Rails 8 (API モード) / Ruby 3.3</li>
            <li>• PostgreSQL 17 + pgvector</li>
            <li>• Solid Queue (非同期ジョブ)</li>
            <li>• Claude API (回答生成)</li>
            <li>• Voyage / OpenAI (ベクトル化)</li>
            <li>• Docker / Vercel / Fly.io</li>
          </ul>
        </details>
      </section>

      <section className="mt-10 flex items-center justify-between gap-4 rounded-lg border bg-background/50 px-4 py-2.5 text-xs text-muted-foreground">
        <span className="font-mono">API status</span>
        {status ? (
          <span className="font-mono text-emerald-600 dark:text-emerald-400">
            ✓ connected
          </span>
        ) : (
          <span className="font-mono text-amber-600 dark:text-amber-400">
            ⚠ backend offline
          </span>
        )}
      </section>
    </div>
  );
}
