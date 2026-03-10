# 合拍 PairTune

一个支持单人也支持双人的协作型任务与积分应用：  
不登录也能使用本地数据；登录后支持云端同步与关系绑定（规划中）。

## 目录结构
- `frontend`：Flutter 客户端
- `backend`：Node.js + Express + SQLite 后端
- `docs`：产品与技术文档

## 关键能力
- 要事第一（四象限任务）
- 积分商城（发布/兑换/记录）
- 通知中心与个人中心
- 账号登录（账号 + 密码）
- 邀请码注册（管理员发放）

## 快速开始
### 后端
```bash
cd /home/talent/projects/priority_first/backend
npm install
node src/main.js
```
看到以下日志代表启动成功：
```
[priority_first_backend] running at http://0.0.0.0:8110
```

### 前端
```bash
cd /home/talent/projects/priority_first/frontend
flutter run
```

### 管理后台（React）
```bash
cd /home/talent/projects/priority_first/admin
npm install
npm run dev
```

## 管理员初始化（推荐）
使用脚本交互输入管理员账号和密码：
```bash
cd /home/talent/projects/priority_first
./backend/scripts/deploy.sh
```
脚本会写入 `backend/.env.local`，并在后端启动时自动创建/更新管理员账号。

## 认证与邀请码
- 登录：账号 + 密码
- 注册：账号 + 密码 + 邀请码
- 邀请码由管理员创建

相关接口（详见 `docs/BACKEND_SCHEMA_AND_API.md`）：
- `POST /auth/register/account`
- `POST /auth/login/account`
- `POST /admin/invite-codes`
- `GET /admin/invite-codes`
- `POST /admin/invite-codes/disable`

## 数据库
SQLite 文件：`backend/data/priority_first.db`  
测试阶段如需重置，可删除该文件后重启后端自动重建。

## 文档
- `docs/BACKEND_SCHEMA_AND_API.md`
- `docs/AUTH_ROADMAP.md`
- `docs/PRODUCT_POSITIONING.md`
- `docs/UI_CURRENT_STATE_AND_NEXT.md`

## 测试
后端集成测试默认不在沙盒环境跑（网络监听被限制）。  
本地可执行：
```bash
ALLOW_NETWORK_TESTS=1 TEST_PORT=8123 node backend/test/auth_account.test.js
```

## 环境变量（部分）
- `ADMIN_ACCOUNT` / `ADMIN_PASSWORD` / `ADMIN_DISPLAY_NAME`
- `SMS_PROVIDER=mock|tencent`
- `EMAIL_PROVIDER=mock|smtp`

更多变量见 `docs/BACKEND_SCHEMA_AND_API.md`。
