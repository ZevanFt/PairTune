# Priority First Backend (SQLite)

独立拆分后端，服务于 `priority_first/frontend`：`要事第一 + 积分商城`。

## 技术栈
- Node.js + Express
- SQLite (`better-sqlite3`)
- 端口：`8110`

## 启动
```bash
cd /home/talent/projects/priority_first/backend
npm install
npm run dev
```

## 部署脚本（推荐）
初始化管理员账号（交互输入），并启动后端：
```bash
cd /home/talent/projects/priority_first
./backend/scripts/deploy.sh
```

使用 pm2 启动：
```bash
cd /home/talent/projects/priority_first
./backend/scripts/deploy.sh --pm2
```
脚本会写入 `backend/.env.local` 保存管理员账号信息（已加入 `.gitignore`）。

## 管理后台（React）
开发模式：
```bash
cd /home/talent/projects/priority_first/admin
npm install
npm run dev
```

生产构建（由后端统一提供）：
```bash
cd /home/talent/projects/priority_first/admin
npm run build
```
构建产物输出到 `backend/public/admin`，访问 `http://127.0.0.1:8110/admin`。

## 一键可用（推荐）
你在终端直接执行下面 3 条：

```bash
cd /home/talent/projects/priority_first/backend
npm install
node src/main.js
```

看到这行代表后端已启动成功：
`[priority_first_backend] running at http://0.0.0.0:8110`

## 验证后端是否正常
```bash
curl http://127.0.0.1:8110/health
```
预期返回 `code: 200`。

## 停止后端
- 在运行后端的那个终端按 `Ctrl + C`。

## API
### 健康检查
- `GET /health`

### 任务
- `GET /tasks?owner=me|partner`
- `POST /tasks`
- `PATCH /tasks/:id?owner=me|partner`
- `DELETE /tasks/:id?owner=me|partner`

### 积分商城
- `GET /store/points?owner=me|partner`
- `POST /store/points/adjust`
- `GET /store/products?viewer=me|partner`
- `GET /store/my-products?owner=me|partner`
- `POST /store/products`
- `PUT /store/products/:id`
- `DELETE /store/products/:id?owner=me|partner`
- `POST /store/exchange`
- `GET /store/owned?owner=me|partner`

### 数据导出
- `GET /export/snapshot`

### 认证（账号）
- `POST /auth/register/account`
- `POST /auth/login/account`

### 管理员（邀请码）
- `POST /admin/invite-codes`
- `GET /admin/invite-codes`
- `POST /admin/invite-codes/disable`

## 数据库文件
- `/home/talent/projects/priority_first/backend/data/priority_first.db`

## 说明
- 与原项目 `/home/talent/projects/our_love` 完全隔离。
- 数据库采用 SQLite，不依赖 MySQL。
