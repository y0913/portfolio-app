"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useState } from "react";

import { buttonVariants } from "@/components/ui/button";
import { ApiError, authApi, type CurrentUser } from "@/lib/api";

type State =
  | { status: "loading" }
  | { status: "authenticated"; user: CurrentUser }
  | { status: "anonymous" };

export function AuthNav() {
  const router = useRouter();
  const pathname = usePathname();
  const [state, setState] = useState<State>({ status: "loading" });

  // Re-probe the session on every route change so that login/logout in another
  // component (e.g. /login form) is reflected in the header without a full reload.
  useEffect(() => {
    let active = true;
    authApi
      .me()
      .then((user) => {
        if (active) setState({ status: "authenticated", user });
      })
      .catch((err) => {
        if (!active) return;
        if (err instanceof ApiError && err.status === 401) {
          setState({ status: "anonymous" });
        } else {
          setState({ status: "anonymous" });
        }
      });
    return () => {
      active = false;
    };
  }, [pathname]);

  async function onLogout() {
    await authApi.logout();
    setState({ status: "anonymous" });
    router.push("/");
    router.refresh();
  }

  if (state.status === "loading") {
    return <div className="h-8 w-20" aria-hidden />;
  }

  if (state.status === "authenticated") {
    return (
      <div className="flex items-center gap-2">
        <Link href="/app" className="text-xs text-muted-foreground hover:text-foreground">
          {state.user.email_address}
        </Link>
        <button
          type="button"
          onClick={onLogout}
          className={buttonVariants({ variant: "ghost", size: "sm" })}
        >
          ログアウト
        </button>
      </div>
    );
  }

  return (
    <div className="flex items-center gap-1">
      <Link href="/login" className={buttonVariants({ variant: "ghost", size: "sm" })}>
        ログイン
      </Link>
      <Link href="/signup" className={buttonVariants({ size: "sm" })}>
        新規登録
      </Link>
    </div>
  );
}
