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
### 开发环境一键启动（推荐）
```bash
cd /home/talent/projects/priority_first
npm install
npm run dev
```
将同时启动：
- 后端 `http://0.0.0.0:8110`
- 管理后台 `http://localhost:5178/admin/`
也可以使用脚本：
```bash
./scripts/dev.sh
```

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

生产构建（由后端统一提供）：
```bash
cd /home/talent/projects/priority_first/admin
npm run build
```
构建产物将输出到 `backend/public/admin`，由后端 `http://127.0.0.1:8110/admin` 提供访问。

## 生产环境脚本（推荐流程）
```bash
cd /home/talent/projects/priority_first
npm run migrate
npm run build:admin
npm run start:backend
```
或使用脚本：
```bash
./scripts/prod.sh
```

## 数据库迁移
迁移文件目录：`backend/migrations`

执行迁移：
```bash
cd /home/talent/projects/priority_first
npm run migrate
```
默认会自动备份数据库到 `backend/backups`（可用 `MIGRATE_SKIP_BACKUP=1` 跳过）。
可通过 `MIGRATE_BACKUP_KEEP=10` 控制保留备份数量。
迁移带锁文件，防止并发执行（如需强制解锁：`MIGRATE_FORCE_UNLOCK=1`）。
锁文件默认 10 分钟过期（可通过 `MIGRATE_LOCK_TTL_MS` 调整）。
迁移锁会检测进程存活，避免误解锁正在执行的迁移。
可选：迁移前自动执行导出流水（`MIGRATE_RUN_PIPELINE=1`）。
可选：迁移失败自动恢复备份（`MIGRATE_AUTO_RESTORE=1`）。
迁移失败可写入通知日志（`NOTIFY_ON_FAIL=1`，写入 `backend/exports/notify.log`）。
迁移前自动导出时，如失败/恢复，会写入对应导出目录 `events.jsonl`。
可选：迁移恢复后自动生成报告（`MIGRATE_REPORT_ON_RESTORE=1`）。
可选：迁移恢复后自动上传导出包（需同时开启 `MIGRATE_RUN_PIPELINE=1`）：
```bash
MIGRATE_UPLOAD_ON_RESTORE=1 MIGRATE_UPLOAD_TARGET=/path/to/upload npm run migrate
```

## 数据库导出
导出数据库快照（JSON）：
```bash
cd /home/talent/projects/priority_first
npm run export
```
可指定输出路径：
```bash
cd /home/talent/projects/priority_first
npm run export -- --out /path/to/snapshot.json
```
导出会输出 SHA256 校验值。
导出数据库快照（SQL）：
```bash
cd /home/talent/projects/priority_first
npm run export:sql
```
可指定输出路径：
```bash
cd /home/talent/projects/priority_first
npm run export:sql -- --out /path/to/snapshot.sql
```
导出会输出 SHA256 校验值。
打包导出（SQL + JSON + migrations）：
```bash
cd /home/talent/projects/priority_first
npm run export:bundle
```
可指定输出目录：
```bash
cd /home/talent/projects/priority_first
npm run export:bundle -- --out /path/to/bundle-dir
```
打包会生成 `MANIFEST.json`，包含每个文件的 SHA256 校验值。
同时会生成 `bundle-*.tar.gz` 压缩包及其 `.sha256` 校验文件（如系统无 `tar` 将跳过压缩）。
校验导出包：
```bash
cd /home/talent/projects/priority_first
npm run verify:bundle -- --dir /path/to/bundle-dir
```
校验单个导出文件：
```bash
cd /home/talent/projects/priority_first
npm run verify:file -- --file /path/to/snapshot.sql
```
压缩导出文件（生成 .gz 与校验）：
```bash
cd /home/talent/projects/priority_first
npm run compress -- --file /path/to/snapshot.sql
```
生成校验报告（汇总所有文件校验状态）：
```bash
cd /home/talent/projects/priority_first
npm run report -- --dir /path/to/bundle-dir
```
一键流水（导出 + 校验 + 报告）：
```bash
cd /home/talent/projects/priority_first
npm run pipeline
```
可指定输出目录：
```bash
cd /home/talent/projects/priority_first
npm run pipeline -- --out /path/to/bundle-dir
```
流水会写入 `events.jsonl`，并在报告中汇总。
可选：自动上传导出包（本地目标路径）：
```bash
PIPELINE_UPLOAD_TO=/path/to/upload npm run pipeline
```
可选：上传后自动校验并生成报告：
```bash
PIPELINE_UPLOAD_TO=/path/to/upload PIPELINE_UPLOAD_VERIFY=1 npm run pipeline
```
单独上传目录或文件：
```bash
npm run upload -- --src /path/to/bundle-dir --dest /path/to/upload
```
上传保留数量（只保留最近 N 份）：
```bash
UPLOAD_KEEP=5 npm run upload -- --src /path/to/bundle-dir --dest /path/to/upload
```
上传后校验并生成报告：
```bash
npm run upload -- --src /path/to/bundle-dir --dest /path/to/upload --verify
```
上传失败删除目标（需开启校验）：
```bash
UPLOAD_VERIFY_FAIL_DELETE=1 npm run upload -- --src /path/to/bundle-dir --dest /path/to/upload --verify
```
上传锁超时（默认 10 分钟）：
```bash
UPLOAD_LOCK_TTL_MS=600000 npm run upload -- --src /path/to/bundle-dir --dest /path/to/upload
```
强制解锁上传：
```bash
UPLOAD_FORCE_UNLOCK=1 npm run upload -- --src /path/to/bundle-dir --dest /path/to/upload
```
上传后自动生成报告：
```bash
UPLOAD_AUTO_REPORT=1 npm run upload -- --src /path/to/bundle-dir --dest /path/to/upload
```
上传失败通知（写入 notify.log）：
```bash
UPLOAD_NOTIFY_ON_FAIL=1 npm run upload -- --src /path/to/bundle-dir --dest /path/to/upload --verify
```
上传成功通知：
```bash
UPLOAD_NOTIFY_ON_OK=1 npm run upload -- --src /path/to/bundle-dir --dest /path/to/upload
```
上传校验失败会写入 `events.jsonl`，可用于报告汇总。
上传失败自动写报告：开启 `UPLOAD_AUTO_REPORT=1` 即可覆盖成功/失败情况。
上传失败自动恢复上一次成功包：
```bash
UPLOAD_RESTORE_ON_FAIL=1 npm run upload -- --src /path/to/bundle-dir --dest /path/to/upload --verify
```

## 数据库备份与恢复（生产建议）
备份：
```bash
cd /home/talent/projects/priority_first
npm run backup
```
备份保留数量（默认 10 份）：
```bash
BACKUP_KEEP=10 npm run backup
```
备份会输出 SHA256 校验值（用于传输完整性校验）。
可选：备份自动压缩（`BACKUP_COMPRESS=1`），并生成 `.gz` 校验文件。
恢复（需指定备份文件）：
```bash
cd /home/talent/projects/priority_first
npm run restore -- --from /path/to/backup.db
```

## 数据库回滚（迁移）
回滚最近一次迁移：
```bash
cd /home/talent/projects/priority_first
npm run migrate -- --down 1
```
回滚指定步数：
```bash
cd /home/talent/projects/priority_first
npm run migrate -- --down 3
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
