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

type FieldErrors = {
  email_address?: string[];
  password?: string[];
  password_confirmation?: string[];
};

export default function SignupPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [fieldErrors, setFieldErrors] = useState<FieldErrors | null>(null);
  const [submitting, setSubmitting] = useState(false);

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError(null);
    setFieldErrors(null);
    setSubmitting(true);
    try {
      await authApi.signup(email, password);
      router.push("/app");
      router.refresh();
    } catch (err) {
      if (err instanceof ApiError && err.status === 422) {
        const body = err.body as { errors?: FieldErrors } | null;
        setFieldErrors(body?.errors ?? null);
        setError("入力内容を確認してください。");
      } else {
        setError("登録に失敗しました。時間をおいて再度お試しください。");
      }
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="container mx-auto flex max-w-md flex-col items-center px-4 py-16 sm:py-24">
      <Card className="w-full">
        <CardHeader className="space-y-1">
          <CardTitle className="text-2xl">新規登録</CardTitle>
          <CardDescription>
            すでにアカウントをお持ちの場合は{" "}
            <Link href="/login" className="font-medium text-foreground underline-offset-4 hover:underline">
              ログイン
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
                aria-invalid={!!fieldErrors?.email_address}
              />
              {fieldErrors?.email_address?.map((msg) => (
                <p key={msg} className="text-xs text-destructive">{msg}</p>
              ))}
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">パスワード (8文字以上)</Label>
              <Input
                id="password"
                type="password"
                autoComplete="new-password"
                minLength={8}
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                aria-invalid={!!fieldErrors?.password}
              />
              {fieldErrors?.password?.map((msg) => (
                <p key={msg} className="text-xs text-destructive">{msg}</p>
              ))}
            </div>
            {error && (
              <p className="text-sm text-destructive" role="alert">
                {error}
              </p>
            )}
            <Button type="submit" className="w-full" disabled={submitting}>
              {submitting ? "送信中..." : "登録"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
