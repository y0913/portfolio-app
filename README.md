# portfolio-app

React (Next.js) フロントエンド × Rails API バックエンドのモノレポ風構成。

```
portfolio-app/
├── backend/   # Rails 8 API (Docker)
└── frontend/  # Next.js 16 (TypeScript + Tailwind)
```

## 必要環境

- Docker Desktop
- Node.js 20+ / npm

## 起動方法

### 1. バックエンド (Rails API + Postgres)

```bash
cd backend
docker compose up -d
docker compose exec api bin/rails db:create   # 初回のみ
```

- API: http://localhost:3001
- 動作確認: `curl http://localhost:3001/api/hello`

停止: `docker compose down`

### 2. フロントエンド (Next.js)

```bash
cd frontend
npm install
npm run dev
```

- http://localhost:3000 を開く
- ホーム画面に Rails API のレスポンスが表示される

## ポート

| サービス | ホスト | コンテナ |
| --- | --- | --- |
| Next.js dev | 3000 | - |
| Rails API | 3001 | 3000 |
| Postgres | 5434 | 5432 |

## CORS

`backend/config/initializers/cors.rb` で `http://localhost:3000` を許可済み。
