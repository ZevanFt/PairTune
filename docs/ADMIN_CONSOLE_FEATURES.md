# 管理后台功能清单（V1）

## 目标
- 管理员可掌握应用运行与运营数据
- 管理员可发放邀请码并管理权限
- 后台权限采用“页面级 + 功能点”模型

## 页面与功能

### 1. 登录
- 账号 + 密码登录
- 仅管理员可访问
- Token 持久化与会话校验

### 1.1 初始化
- 首次启动进入初始化页面
- 录入管理员账号与密码
- 初始化完成后进入登录页

### 2. 仪表盘（Dashboard）
- 今日新增用户
- DAU/WAU/MAU
- 任务创建/完成数与完成率
- 积分发放/消耗与净流通
- 商城兑换量与转化率
- 邀请码生成/使用/转化率
- 系统健康状态

### 3. 用户运营
- 用户列表（账号/昵称/角色/状态/创建时间）
- 搜索与筛选

### 4. 任务运营
- 任务创建趋势
- 任务完成率趋势
- 四象限分布
- 重复任务占比

### 5. 积分运营
- 发放来源分布
- 消耗去向分布
- 人均积分与余额区间分布

### 6. 商城运营
- 商品发布趋势
- 兑换趋势
- 热门商品排行
- 兑换失败原因统计

### 7. 邀请码管理
- 生成邀请码（数量/使用次数/过期）
- 查看邀请码列表
- 禁用邀请码

### 8. 权限与角色
- 角色列表
- 角色权限配置
- 用户角色绑定

### 9. 安全与会话
- 会话列表（只读）
- 安全事件（失败登录/锁定/限流）

### 10. 系统设置
- Provider 状态（短信/邮件）
- 管理员账号信息

## 权限点（页面级 + 功能点）
- `admin.dashboard.view`
- `admin.stats.view`
- `admin.users.view`
- `admin.tasks.view`
- `admin.points.view`
- `admin.store.view`
- `admin.invites.view`
- `admin.invites.manage`
- `admin.roles.view`
- `admin.roles.manage`
- `admin.security.view`
- `admin.sessions.view`
- `admin.settings.view`
- `admin.full`（全量管理）

## 后端接口建议
- `GET /admin/stats/overview?range=7d|30d|90d`
- `GET /admin/stats/series?range=7d|30d|90d`
- `GET /admin/stats/tasks?range=7d|30d|90d`
- `GET /admin/stats/points?range=7d|30d|90d`
- `GET /admin/stats/store?range=7d|30d|90d`
- `GET /admin/stats/invite?range=7d|30d|90d`
- `GET /admin/security/events?range=7d|30d|90d&limit=50`
- `GET /admin/settings`
- `GET /admin/bootstrap/status`
- `POST /admin/bootstrap`

## 说明
后台只读统计接口与角色权限接口均需 `role=admin` 或具备相应权限点。
