export function SiteFooter() {
  return (
    <footer className="border-t border-border/40">
      <div className="container mx-auto flex max-w-5xl flex-col items-center justify-between gap-2 px-4 py-6 text-sm text-muted-foreground sm:flex-row">
        <p>
          A technical demo by{" "}
          <a
            href="https://www.build-llc.jp"
            target="_blank"
            rel="noopener noreferrer"
            className="font-medium underline-offset-4 hover:underline"
          >
            合同会社Build
          </a>
        </p>
        <p>
          <a
            href="https://github.com/y0913/portfolio-app"
            target="_blank"
            rel="noopener noreferrer"
            className="hover:underline"
          >
            Source on GitHub
          </a>
        </p>
      </div>
    </footer>
  );
}
