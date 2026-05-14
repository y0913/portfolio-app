"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { FileText, Loader2, Trash2, Upload } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { ApiError, documentsApi, type DocumentSummary } from "@/lib/api";

function formatBytes(n: number | null): string {
  if (n == null) return "—";
  if (n < 1024) return `${n} B`;
  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`;
  return `${(n / 1024 / 1024).toFixed(1)} MB`;
}

const statusLabel: Record<DocumentSummary["status"], string> = {
  pending: "待機中",
  processing: "処理中",
  ready: "完了",
  failed: "失敗",
};

const statusColor: Record<DocumentSummary["status"], string> = {
  pending: "text-muted-foreground",
  processing: "text-amber-600 dark:text-amber-400",
  ready: "text-emerald-600 dark:text-emerald-400",
  failed: "text-destructive",
};

export default function DocumentsPage() {
  const [docs, setDocs] = useState<DocumentSummary[] | null>(null);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  const refresh = useCallback(async () => {
    try {
      const { documents } = await documentsApi.list();
      setDocs(documents);
    } catch {
      setDocs([]);
    }
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  // Poll while any doc is still processing
  useEffect(() => {
    if (!docs) return;
    const inFlight = docs.some((d) => d.status === "pending" || d.status === "processing");
    if (!inFlight) return;
    const id = setInterval(refresh, 1500);
    return () => clearInterval(id);
  }, [docs, refresh]);

  async function onUpload(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    setError(null);
    setUploading(true);
    try {
      await documentsApi.upload(file);
      await refresh();
    } catch (err) {
      if (err instanceof ApiError) {
        const body = err.body as { error?: string } | null;
        setError(body?.error ?? "アップロードに失敗しました。");
      } else {
        setError("アップロードに失敗しました。");
      }
    } finally {
      setUploading(false);
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  }

  async function onDelete(id: number) {
    if (!confirm("この資料を削除しますか？")) return;
    try {
      await documentsApi.destroy(id);
      await refresh();
    } catch {
      setError("削除に失敗しました。");
    }
  }

  return (
    <div className="container mx-auto max-w-3xl px-4 py-12">
      <div className="mb-6 flex items-end justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">資料</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            テキスト形式 (.txt / .md) の資料を取り込みます。最大 2 MB。
          </p>
        </div>
        <div>
          <Input
            ref={fileInputRef}
            type="file"
            accept=".txt,.md,.markdown,text/plain,text/markdown"
            onChange={onUpload}
            disabled={uploading}
            className="hidden"
            id="file-upload"
          />
          <Button disabled={uploading} onClick={() => fileInputRef.current?.click()}>
            {uploading ? (
              <>
                <Loader2 className="mr-1.5 h-4 w-4 animate-spin" />
                送信中
              </>
            ) : (
              <>
                <Upload className="mr-1.5 h-4 w-4" />
                追加
              </>
            )}
          </Button>
        </div>
      </div>

      {error && (
        <p className="mb-4 rounded-md border border-destructive/30 bg-destructive/5 px-3 py-2 text-sm text-destructive">
          {error}
        </p>
      )}

      {docs == null ? (
        <p className="text-sm text-muted-foreground">読み込み中...</p>
      ) : docs.length === 0 ? (
        <Card className="border-dashed">
          <CardHeader>
            <CardTitle className="text-base">まだ資料がありません</CardTitle>
            <CardDescription>
              右上の「追加」から .txt / .md ファイルをアップロードしてください。
            </CardDescription>
          </CardHeader>
        </Card>
      ) : (
        <div className="space-y-2">
          {docs.map((d) => (
            <Card key={d.id} className="border-border/60">
              <CardContent className="flex items-center justify-between gap-4 py-3">
                <div className="flex min-w-0 items-center gap-3">
                  <FileText className="h-4 w-4 shrink-0 text-muted-foreground" />
                  <div className="min-w-0">
                    <p className="truncate font-medium">{d.title}</p>
                    <p className="text-xs text-muted-foreground">
                      {d.filename} · {formatBytes(d.byte_size)} · チャンク {d.chunks_count}
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-3">
                  <span className={`text-xs font-medium ${statusColor[d.status]}`}>
                    {statusLabel[d.status]}
                  </span>
                  <button
                    type="button"
                    onClick={() => onDelete(d.id)}
                    className="text-muted-foreground transition-colors hover:text-destructive"
                    aria-label="削除"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
