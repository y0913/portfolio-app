"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { ArrowRight, FileText, MessagesSquare } from "lucide-react";

import { buttonVariants } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { cn } from "@/lib/utils";
import { documentsApi, type DocumentSummary } from "@/lib/api";

type DocsState =
  | { status: "loading" }
  | { status: "loaded"; documents: DocumentSummary[] }
  | { status: "error" };

export default function AppHome() {
  const [state, setState] = useState<DocsState>({ status: "loading" });

  useEffect(() => {
    let alive = true;
    documentsApi
      .list()
      .then(({ documents }) => {
        if (alive) setState({ status: "loaded", documents });
      })
      .catch(() => {
        if (alive) setState({ status: "error" });
      });
    return () => {
      alive = false;
    };
  }, []);

  const documents = state.status === "loaded" ? state.documents : [];
  const ready = documents.filter((d) => d.status === "ready");
  const hasReady = ready.length > 0;

  return (
    <div className="container mx-auto max-w-3xl px-4 py-12">
      <div className="mb-8">
        <h1 className="text-2xl font-semibold tracking-tight">ようこそ</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          ここからドキュメントの取り込みとチャットを試せます。
        </p>
      </div>

      {state.status === "loaded" && !hasReady && (
        <div className="mb-6 rounded-lg border border-amber-500/30 bg-amber-500/5 px-4 py-3 text-sm">
          <p className="font-medium text-amber-700 dark:text-amber-300">
            まだ準備できた資料がありません。
          </p>
          <p className="mt-1 text-muted-foreground">
            チャットを始めるには、まず .txt / .md の資料を取り込んでください。
          </p>
        </div>
      )}

      <div className="grid gap-4 sm:grid-cols-2">
        <Card className={cn(!hasReady && "ring-1 ring-primary/40")}>
          <CardHeader>
            <div className="flex items-center justify-between">
              <FileText className="h-4 w-4 text-muted-foreground" />
              {state.status === "loaded" && (
                <span className="text-xs text-muted-foreground">
                  {documents.length} 件 ({ready.length} 件処理済)
                </span>
              )}
            </div>
            <CardTitle className="text-base">資料を追加する</CardTitle>
            <CardDescription>
              .txt / .md をアップロードして、AIに読み込ませます。
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Link
              href="/app/documents"
              className={buttonVariants({ variant: hasReady ? "outline" : "default" })}
            >
              資料を管理
              <ArrowRight className="ml-1 h-4 w-4" />
            </Link>
          </CardContent>
        </Card>

        <Card className={cn(!hasReady && "opacity-60")}>
          <CardHeader>
            <div className="flex items-center justify-between">
              <MessagesSquare className="h-4 w-4 text-muted-foreground" />
            </div>
            <CardTitle className="text-base">質問してみる</CardTitle>
            <CardDescription>
              {hasReady
                ? "取り込んだ資料をもとに、AIに自然な日本語で質問できます。"
                : "資料を1件以上取り込むと、質問できるようになります。"}
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Link
              href="/app/chat"
              aria-disabled={!hasReady}
              tabIndex={hasReady ? 0 : -1}
              className={cn(
                buttonVariants({ variant: "outline" }),
                !hasReady && "pointer-events-none"
              )}
            >
              チャットを開く
            </Link>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
