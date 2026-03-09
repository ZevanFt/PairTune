# 合拍 PairTune 后端数据表与 API 说明

更新时间：2026-03-10

## 1. 技术与边界
- 运行时：Node.js + Express
- 存储：SQLite (`better-sqlite3`)
- 监听端口：`8110`
- 当前身份模型：`owner = me | partner`（参数级，非真正登录鉴权）

## 2. 数据表设计

### 2.1 `tasks`
任务主表（要事第一）
- `id` INTEGER PK AUTOINCREMENT
- `owner` TEXT NOT NULL (`me|partner`)
- `title` TEXT NOT NULL
- `note` TEXT
- `quadrant` INTEGER NOT NULL
- `points` INTEGER NOT NULL DEFAULT 0
- `due_date` TEXT
- `due_mode` TEXT NOT NULL DEFAULT 'day' (`day|time`)
- `repeat_type` TEXT NOT NULL DEFAULT 'none' (`none|daily|weekly|weekly_custom|monthly|yearly`)
- `repeat_interval` INTEGER NOT NULL DEFAULT 1
- `repeat_weekdays` TEXT (例如 `1,3,5` 表示周一/周三/周五)
- `repeat_until` TEXT
- `is_done` INTEGER NOT NULL DEFAULT 0
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL

### 2.2 `point_wallets`
积分钱包
- `owner` TEXT PK
- `points` INTEGER NOT NULL DEFAULT 0
- `updated_at` TEXT NOT NULL

### 2.3 `point_ledger`
积分流水
- `id` INTEGER PK AUTOINCREMENT
- `owner` TEXT NOT NULL
- `amount` INTEGER NOT NULL
- `reason` TEXT NOT NULL
- `created_at` TEXT NOT NULL

### 2.4 `products`
商城商品
- `id` INTEGER PK AUTOINCREMENT
- `publisher` TEXT NOT NULL
- `name` TEXT NOT NULL
- `description` TEXT
- `points_cost` INTEGER NOT NULL
- `stock` INTEGER NOT NULL DEFAULT 0
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL

### 2.5 `owned_items`
已兑换记录
- `id` INTEGER PK AUTOINCREMENT
- `owner` TEXT NOT NULL
- `product_id` INTEGER NOT NULL
- `product_name` TEXT NOT NULL
- `points_spent` INTEGER NOT NULL
- `created_at` TEXT NOT NULL

### 2.6 `profiles`
个人资料
- `owner` TEXT PK
- `display_name` TEXT NOT NULL
- `bio` TEXT
- `avatar` TEXT
- `relationship_label` TEXT NOT NULL DEFAULT '搭档'
- `updated_at` TEXT NOT NULL

### 2.7 `app_settings`
应用设置
- `owner` TEXT PK
- `duo_enabled` INTEGER NOT NULL DEFAULT 0
- `notifications_enabled` INTEGER NOT NULL DEFAULT 1
- `quiet_hours_start` TEXT
- `quiet_hours_end` TEXT
- `updated_at` TEXT NOT NULL

### 2.8 `notifications`
站内通知
- `id` INTEGER PK AUTOINCREMENT
- `owner` TEXT NOT NULL
- `type` TEXT NOT NULL (`task|exchange|relation|system`)
- `title` TEXT NOT NULL
- `body` TEXT NOT NULL
- `is_read` INTEGER NOT NULL DEFAULT 0
- `created_at` TEXT NOT NULL

### 2.9 `auth_users`（新增）
账号用户表（手机号 / 微信）
- `id` INTEGER PK AUTOINCREMENT
- `phone` TEXT UNIQUE (可空)
- `wechat_openid` TEXT UNIQUE (可空)
- `password_hash` TEXT (可空，微信账号可无密码)
- `display_name` TEXT NOT NULL
- `status` TEXT NOT NULL DEFAULT `active`
- `created_at` TEXT NOT NULL
- `updated_at` TEXT NOT NULL

### 2.10 `auth_sessions`（新增）
登录会话表（Token）
- `token` TEXT PK
- `user_id` INTEGER NOT NULL
- `provider` TEXT NOT NULL (`phone|wechat`)
- `owner_hint` TEXT NOT NULL DEFAULT `me`
- `expires_at` TEXT NOT NULL
- `created_at` TEXT NOT NULL
- `last_seen_at` TEXT NOT NULL

## 3. API 清单

### 3.1 Health
- `GET /health`

### 3.2 任务
- `GET /tasks?owner=me|partner`
- `POST /tasks`
- `PATCH /tasks/:id?owner=me|partner`
- `DELETE /tasks/:id?owner=me|partner`

重复任务规则：
- 当任务 `repeat_type != none` 且从未完成变为已完成时，后端会自动生成下一次任务。
- `daily|weekly|monthly|yearly`：下一次 `due_date` 按 `repeat_interval` 递增。
- `weekly_custom`：按 `repeat_weekdays` 计算最近的下一个周几。
- 如果设置了 `repeat_until`，超过截止日期不再生成新任务。

截止时间规则：
- `due_mode = day`：表示“当天截止”，后端会将时间统一为 `23:59:59.999`。
- `due_mode = time`：表示“精确时分截止”，后端保留具体时间点。

### 3.3 商城与积分
- `GET /store/points?owner=me|partner`
- `POST /store/points/adjust`
- `GET /store/products?viewer=me|partner`
- `GET /store/my-products?owner=me|partner`
- `POST /store/products`
- `PUT /store/products/:id`
- `DELETE /store/products/:id?owner=me|partner`
- `POST /store/exchange`
- `GET /store/owned?owner=me|partner`

### 3.4 资料与设置（新增）
- `GET /profile?owner=me|partner`
- `PUT /profile`
- `GET /settings?owner=me|partner`
- `PUT /settings`

### 3.5 通知中心（新增）
- `GET /notifications?owner=me|partner&status=all|unread&limit=1..100`
- `POST /notifications`
- `POST /notifications/mark-read`
- `POST /notifications/mark-all-read`

### 3.6 快照导出
- `GET /export/snapshot`
  - 现包含：`tasks/points/ledger/products/owned_items/profiles/settings/notifications/auth_users/auth_sessions`

### 3.7 认证（新增）
- `POST /auth/register/phone`
  - 入参：`phone/password/display_name`
  - 规则：手机号必须 11 位（`1xxxxxxxxxx`），密码至少 6 位
- `POST /auth/login/phone`
  - 入参：`phone/password`
  - 返回：`token/provider/expires_at/user`
- `POST /auth/phone/send-code`
  - 入参：`phone/purpose(login|register)`
  - 限流：同手机号 60 秒内不可重复发码
  - 过期：验证码 5 分钟有效
- `POST /auth/login/phone-code`
  - 入参：`phone/code`
  - 说明：验证码登录（provider=`phone_code`）
- `POST /auth/register/phone-code`
  - 入参：`phone/code/display_name/password?`
  - 说明：验证码注册成功后直接签发会话
- `POST /auth/login/wechat`
  - 入参：`wechat_code/display_name`
  - 当前为占位接入：用 `wechat_code` 映射 `wechat_openid`
  - 返回：`token/provider/expires_at/user`
- `GET /auth/session?token=...`
  - 校验会话并返回用户信息，过期会自动清理
- `POST /auth/logout`
  - 入参：`token`

## 4. 请求示例

### 4.1 更新资料
```json
PUT /profile
{
  "owner": "me",
  "display_name": "小合",
  "bio": "今天也在稳步前进",
  "relationship_label": "闺蜜"
}
```

### 4.2 更新设置
```json
PUT /settings
{
  "owner": "me",
  "duo_enabled": true,
  "notifications_enabled": true,
  "quiet_hours_start": "23:00",
  "quiet_hours_end": "08:00"
}
```

### 4.3 标记通知已读
```json
POST /notifications/mark-read
{
  "owner": "me",
  "id": 12
}
```

## 5. 当前风险与待升级
- 已有基础账号会话模型（`auth_users/auth_sessions`），但仍未接入真实短信验证码与微信 OAuth
- `owner` 参数模型仍用于业务视角切换，生产环境建议替换为“会话用户 + 关系绑定”模型
- 缺少接口级测试与迁移版本管理（目前为启动时自动建表）
- 建议下一阶段引入：
  - 关系绑定邀请码（把 `me|partner` 迁移为真实双人关系）
  - 统一操作日志
  - API 输入校验库（如 zod / joi）
