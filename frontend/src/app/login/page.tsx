"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";

import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { ApiError, authApi } from "@/lib/api";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await authApi.login(email, password);
      router.push("/app");
      router.refresh();
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) {
        setError("メールアドレスまたはパスワードが違います。");
      } else if (err instanceof ApiError && err.status === 429) {
        setError("試行回数が多すぎます。しばらく待ってからやり直してください。");
      } else {
        setError("ログインに失敗しました。時間をおいて再度お試しください。");
      }
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="container mx-auto flex max-w-md flex-col items-center px-4 py-16 sm:py-24">
      <Card className="w-full">
        <CardHeader className="space-y-1">
          <CardTitle className="text-2xl">ログイン</CardTitle>
          <CardDescription>
            アカウントをお持ちでない場合は{" "}
            <Link href="/signup" className="font-medium text-foreground underline-offset-4 hover:underline">
              新規登録
            </Link>
            してください。
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form className="space-y-4" onSubmit={onSubmit}>
            <div className="space-y-2">
              <Label htmlFor="email">メールアドレス</Label>
              <Input
                id="email"
                type="email"
                autoComplete="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">パスワード</Label>
              <Input
                id="password"
                type="password"
                autoComplete="current-password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>
            {error && (
              <p className="text-sm text-destructive" role="alert">
                {error}
              </p>
            )}
            <Button type="submit" className="w-full" disabled={submitting}>
              {submitting ? "送信中..." : "ログイン"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
