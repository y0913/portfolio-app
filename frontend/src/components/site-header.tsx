import Link from "next/link";
import { AuthNav } from "@/components/auth-nav";
import { ThemeToggle } from "@/components/theme-toggle";

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-40 w-full border-b border-border/40 bg-background/80 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container mx-auto flex h-14 max-w-5xl items-center justify-between px-4">
        <Link href="/" className="flex items-center gap-2 font-semibold">
          <span className="inline-block size-6 rounded-md bg-foreground text-background grid place-items-center text-xs">
            D
          </span>
          <span>Doc Q&amp;A</span>
        </Link>
        <nav className="flex items-center gap-2">
          <AuthNav />
          <ThemeToggle />
        </nav>
      </div>
    </header>
  );
}
