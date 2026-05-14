import Link from "next/link";

import { buttonVariants } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";

export default function AppHome() {
  return (
    <div className="container mx-auto max-w-3xl px-4 py-12">
      <div className="mb-8">
        <h1 className="text-2xl font-semibold tracking-tight">ようこそ</h1>
        <p className="mt-1 text-sm text-muted-foreground">
          ここからドキュメントの取り込みとチャットを試せます。
        </p>
      </div>
      <div className="grid gap-4 sm:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="text-base">資料を追加する</CardTitle>
            <CardDescription>
              PDF・テキストをアップロードして、AIに読み込ませます。
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Link
              href="#"
              aria-disabled
              className={buttonVariants({ variant: "outline" })}
            >
              準備中
            </Link>
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle className="text-base">質問してみる</CardTitle>
            <CardDescription>
              取り込んだ資料をもとに、AIに自然な日本語で質問できます。
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Link
              href="#"
              aria-disabled
              className={buttonVariants({ variant: "outline" })}
            >
              準備中
            </Link>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
