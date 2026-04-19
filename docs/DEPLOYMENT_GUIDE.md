# 部署与运行指南（归档）

## 1. 开发环境（推荐）
前置：Node.js 18+、npm、Flutter（仅移动端需要）

一键启动（后端 + 管理后台）：
```bash
cd /home/talent/projects/priority_first
npm install
npm run dev
```
启动后访问：
- 后端：`http://0.0.0.0:8110`
- 管理后台：`http://localhost:5178/admin/`

也可以使用脚本：
```bash
./scripts/dev.sh
```

移动端（Flutter）单独启动：
```bash
cd /home/talent/projects/priority_first/frontend
flutter run
```

## 2. 生产环境（推荐流程）
前置：Node.js 18+、npm

1) 数据库迁移（建议每次部署前执行）
```bash
cd /home/talent/projects/priority_first
npm run migrate
```

2) 构建管理后台并由后端托管静态资源
```bash
cd /home/talent/projects/priority_first
npm run build:admin
```

3) 启动后端
```bash
cd /home/talent/projects/priority_first
npm run start:backend
```

或使用脚本：
```bash
./scripts/prod.sh
```

## 2.1 生产进程守护（PM2 推荐）
安装：
```bash
npm i -g pm2
```

使用 PM2 启动后端（推荐用配置文件）：
```bash
cd /home/talent/projects/priority_first
pm2 start ecosystem.config.cjs
pm2 save
```

常用命令：
```bash
pm2 list
pm2 logs priority_first_backend
pm2 restart priority_first_backend
pm2 stop priority_first_backend
```

如果仅需要命令行快速启动：
```bash
pm2 start backend/src/main.js --name priority_first_backend --cwd /home/talent/projects/priority_first/backend
pm2 save
```

## 3. 管理员初始化
仅前端初始化（首次访问管理后台会提示）：
- 打开管理后台页面
- 填写管理员账号与密码
- 前端调用后端接口完成初始化

## 4. 数据库导出与校验（上线配套）
导出 SQL（推荐做迁移前备份）：
```bash
cd /home/talent/projects/priority_first
npm run export:sql
```

导出 JSON（用于调试/检查）：
```bash
cd /home/talent/projects/priority_first
npm run export
```

打包导出（SQL + JSON + migrations + 校验）：
```bash
cd /home/talent/projects/priority_first
npm run export:bundle
```

校验导出包：
```bash
cd /home/talent/projects/priority_first
npm run verify:bundle -- --dir /path/to/bundle-dir
```

## 5. 数据库备份与恢复（生产建议）
备份：
```bash
cd /home/talent/projects/priority_first
npm run backup
```

恢复：
```bash
cd /home/talent/projects/priority_first
npm run restore -- --from /path/to/backup.db
```

## 6. 常见问题
Q: 数据库存储时间是中国时间吗？  
A: 数据库统一存 UTC（`toISOString()`），前端展示会按 `Asia/Shanghai` 进行转换。
