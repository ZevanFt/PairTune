# Priority First + Store App (Split)

情侣双人小 App：`要事第一 + 积分商城`。

## 目录
- Monorepo 根目录: `/home/talent/projects/priority_first`
- Frontend(App): `/home/talent/projects/priority_first/frontend`
- Backend(SQLite): `/home/talent/projects/priority_first/backend`

## 启动顺序
1. 启动后端（SQLite）
```bash
cd /home/talent/projects/priority_first/backend
npm run dev
```

2. 启动 Flutter 子 App
```bash
cd /home/talent/projects/priority_first/frontend
flutter pub get
flutter run
```

## 真机连接你电脑本地后端
如果你用 Android 真机，需要把 API 指向你电脑局域网 IP（例如 `192.168.1.3`）：

```bash
cd /home/talent/projects/priority_first/frontend
flutter run -d <你的设备ID> --dart-define=API_BASE_URL=http://192.168.1.3:8110
```

设备 ID 可通过下列命令查看：
```bash
flutter devices
```

## 当前功能
- 要事第一（四象限）：新增任务、编辑任务、完成任务、删除任务（支持我/对象分视图）
- 积分商城：
  - 查看积分余额（我/对象）
  - 发布商品（我/对象）
  - 编辑/下架自己发布的商品
  - 兑换对象发布商品
  - 查看已兑换记录
  - 一键导出后端快照（任务/积分/商品/已兑）
- 任务完成自动加积分（按任务积分奖励）

## 数据源策略
- 默认走后端 API（`http://127.0.0.1:8110`，Android 模拟器 `10.0.2.2:8110`）
- 后端不可用时：任务模块自动降级本地 SQLite

## 不影响原工程
- 未修改原始业务仓库代码路径：`/home/talent/projects/our_love/*`
- 拆分开发全部位于：
  - `/home/talent/projects/priority_first/frontend`
  - `/home/talent/projects/priority_first/backend`

## Git 只拉后端说明
如果未来你把 `priority_first` 作为一个仓库，想只检出后端目录，可用 sparse-checkout：

```bash
git clone <repo-url> priority_first
cd priority_first
git sparse-checkout init --cone
git sparse-checkout set backend
```

这样工作区只会拉取 `backend` 目录内容。
