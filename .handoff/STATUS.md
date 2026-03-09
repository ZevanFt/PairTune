# Priority First 拆分项目交接清单

更新时间：2026-03-08

## 已完成
- [x] 拆分项目目录重组为单一根目录：
  - `/home/talent/projects/priority_first/frontend`
  - `/home/talent/projects/priority_first/backend`
- [x] 保留兼容软链接：
  - `/home/talent/projects/priority_first_app -> .../priority_first/frontend`
  - `/home/talent/projects/priority_first_backend -> .../priority_first/backend`
- [x] 后端（SQLite）基础能力完成：
  - 任务 CRUD（含 `owner=me|partner` 访问控制）
  - 积分钱包、积分流水、商城发布/兑换
  - 商品编辑/下架
  - `GET /export/snapshot`
- [x] 前端（Flutter）基础能力完成：
  - 要事第一：新增/编辑/删除/完成任务
  - 任务筛选与排序（全部/未完成/已完成；更新时间/截止时间/积分）
  - 积分商城：发布、兑换、已兑记录、编辑/下架、快照导出提示
- [x] 首屏体验优化：
  - 首页与商城页已加骨架屏
  - 刷新时保留旧内容，顶部细进度条，不再整屏空白
- [x] 真机调试链路打通：
  - `adb reverse tcp:8110 tcp:8110`
  - `flutter run -d 55c83fe9` 可启动
- [x] Android NDK 版本已修复：
  - `android/app/build.gradle.kts` 使用 `ndkVersion = "27.0.12077973"`
- [x] README 已补充启动步骤与真机连本地后端说明

## 进行中 / 待确认
- [ ] 统一后端常驻启动方式（当前可手动 `npm run dev`，后续可补脚本）
- [ ] 骨架屏升级为 shimmer 动效（当前是静态骨架块）
- [ ] 商城与任务页 UI 视觉重设计（现阶段可用优先）

## 下一步建议（按优先级）
1. 增加一键脚本：后端“杀旧进程 + 启动 + health 检查”
2. 完成 shimmer 骨架与空态插画
3. 增加前端基础回归测试（任务/商城关键流程）

## 一键运行命令
```bash
# 后端
cd /home/talent/projects/priority_first/backend
npm run dev

# 真机端口映射（USB 调试）
adb reverse tcp:8110 tcp:8110

# 前端
cd /home/talent/projects/priority_first/frontend
flutter run -d 55c83fe9
```

## Codex 项目解读记录（2026-03-08）
- 项目形态：`frontend`(Flutter) + `backend`(Node.js/Express + SQLite) 的前后端拆分架构。
- 当前完成度：任务 CRUD、积分钱包/流水、商城发布/兑换/编辑/下架、快照导出已打通，真机调试链路已可用。
- 前端主流程：
  - `要事第一`：任务新增/编辑/删除/完成，支持筛选与排序。
  - `积分商城`：积分展示、商品管理、兑换、已兑记录、快照导出。
- 后端主流程：
  - 任务：`/tasks` 系列接口，按 `owner=me|partner` 控制视角。
  - 积分：`point_wallets + point_ledger`，支持手动调整与任务完成加分。
  - 商城：`products + owned_items`，支持发布/编辑/下架与兑换事务。
- 数据策略：前端任务模块在后端不可用时降级本地 SQLite；商城主要依赖后端。
- 主要风险：
  - 缺少真实鉴权（owner 仅参数约定）。
  - 输入校验边界不完整（负值/范围约束不足）。
  - 自动化测试不足（前端仅 smoke，后端缺系统测试）。
  - 仓库中存在构建产物与依赖目录，需进一步规范化（.gitignore/清理）。
- 后续方向：结合即将提供的网站，重点学习并迁移 UI 视觉体系、交互分层与组件化样式策略。

## Codex UI 提升记录（2026-03-08）
- 已引入统一主题文件：`frontend/lib/ui/app_theme.dart`
  - 统一色板（ink/blush/peach/mint/sky/paper）
  - 统一卡片、AppBar、SnackBar 视觉基线
- 已新增 shimmer 动效组件：`frontend/lib/widgets/shimmer_block.dart`
  - 用于任务页与商城页加载骨架屏
- 已完成页面视觉重构：
  - `frontend/lib/pages/home_page.dart`
    - 增加顶部 Hero 信息卡（今日聚焦、进行中/已完成指标）
    - 骨架屏替换为 shimmer 动效
    - 过滤与排序区改为更明确分层样式
    - 页面背景升级为分层渐变
  - `frontend/lib/pages/store_page.dart`
    - 页面背景升级为分层渐变
    - 积分卡样式重构（深色主卡 + 指标强调）
    - 骨架屏替换为 shimmer 动效
- 已切换全局主题入口：`frontend/lib/main.dart` 使用 `AppTheme.light()`
- 验证结果：`flutter analyze` 通过（No issues found）

## Codex 品牌与信息架构更新（2026-03-08）
- 品牌命名已收敛：中文 `合拍`，英文 `PairTune`
- 已将 App 标题调整为 `合拍 PairTune`
- 已完成底部导航升级：`任务 / 商城 / 通知 / 我的`
- 已新增页面：
  - `frontend/lib/pages/notifications_page.dart`
  - `frontend/lib/pages/profile_page.dart`
- 已完成非默认原生风格底栏：`main.dart` 内 `_BrandBottomBar`
- 已新增产品定位文档：`docs/PRODUCT_POSITIONING.md`
- 验证结果：`flutter analyze` 通过（No issues found）

## Codex 单人/双人模式改造（2026-03-08）
- 已支持首启模式选择：`先单人开始` / `邀请搭档一起`
- 已新增运行时模式状态：单人可用，双人增强
- 任务页改造：
  - 单人模式隐藏 owner 切换
  - 双人模式显示 `我/搭档` 视角切换
- 商城页改造：
  - 单人模式隐藏 owner 切换
  - 保留积分与“我发布的商品”能力
  - 双人兑换区在单人模式给出明确引导文案
- 个人页改造：新增“双人协作模式”开关，可在单人/双人间切换
- 验证：`flutter analyze` 通过（No issues found）

## Codex UI + API 完善（2026-03-08）
- 后端新增数据表：`profiles` / `app_settings` / `notifications`
- 后端新增 API：
  - `GET/PUT /profile`
  - `GET/PUT /settings`
  - `GET /notifications`
  - `POST /notifications`
  - `POST /notifications/mark-read`
  - `POST /notifications/mark-all-read`
- 快照导出已扩展：`profiles/settings/notifications`
- 前端新增服务：`frontend/lib/services/account_api_service.dart`
- 通知页已改为真实后端数据驱动，支持单条已读/全部已读
- 个人页已改为真实后端数据驱动，支持昵称编辑与通知开关持久化
- 主导航已接入 owner 透传，通知与我的页面按当前 owner 读取数据
- 文档补齐：`docs/BACKEND_SCHEMA_AND_API.md`
- 验证：
  - `node --check backend/src/main.js` 通过
  - `flutter analyze` 通过（No issues found）

## Codex 重复任务能力（2026-03-08）
- 后端 `tasks` 已支持重复字段：`repeat_type/repeat_interval/repeat_until`
- 任务完成时自动生成下一次任务（daily/weekly/monthly）
- 到达 `repeat_until` 后停止生成
- 前端编辑任务页已支持设置重复规则与间隔
- 任务列表已展示重复信息标签
- 本地 SQLite 降级库已升级到 v2，支持重复字段
- 文档已补充：`docs/BACKEND_SCHEMA_AND_API.md`
- 验证：
  - `node --check backend/src/main.js` 通过
  - `flutter analyze` 通过（No issues found）

## Codex 时间语义与高级重复规则（2026-03-08）
- 已升级 `tasks` 字段：
  - 新增 `due_mode`（`day|time`）
  - 新增 `repeat_weekdays`（周几重复）
  - `repeat_type` 扩展支持 `weekly_custom|yearly`
- 截止语义明确：
  - `day` 模式按当天 23:59:59.999 处理
  - `time` 模式按精确时分处理
- 重复规则升级：
  - 支持每天/每周/每月/每年/按周几重复
  - 完成任务后自动生成下一次实例
  - `repeat_until` 到期后停止生成
- 前端编辑页升级：
  - 引入自定义日期选择器（参考 our_love 组件迁移）
  - 新增截止模式选择（当天截止/精确时间）
  - 新增按周几重复（周一~周日多选）
- 主题变量升级：`AppTheme` 补充通用色值 token（primary/surface/border/textMuted/success/warning/danger）
- 文档新增与更新：
  - `docs/TASK_TIME_AND_RECURRENCE_DESIGN.md`
  - `docs/BACKEND_SCHEMA_AND_API.md`（同步新字段和语义）
- 验证：
  - `node --check backend/src/main.js` 通过
  - `flutter analyze` 通过（No issues found）

## Codex 错误展示与联通日志优化（2026-03-08）
- 前端错误展示统一为：`状态码 + 状态文字`（不再直接展示长异常串）
- 新增统一错误类型：`services/api_error.dart`（ApiHttpError）
- 新增错误格式化工具：`utils/error_display.dart`
- Task/Store/Account API 服务已加请求/响应日志（method/path/status）
- `ApiConfig` 启动后会打印一次实际 `baseUrl` 与平台信息，便于确认是否命中本地后端
- Home/Store/Notifications/Profile 页面已切换为统一错误文案展示
- 验证：`flutter analyze` 通过（No issues found）

## Codex UI 视觉二次优化（2026-03-09）
- 已按 `impeccable.style` 的视觉方法完成首页与商城页二次重构（强调层级、节奏、胶囊信息、卡片分区）
- 首页（`frontend/lib/pages/home_page.dart`）
  - Hero 区升级：增加完成率、双指标卡、强化标题层级与阴影深度
  - 四象限卡升级：统一图标语义、色块与点击引导文案
  - 任务列表升级：改为卡片式任务项，元信息 Chip 化展示（象限/截止/积分/重复）
  - 错误 Banner 改为紧凑提示块，保证状态可见且不破坏主布局
- 商城页（`frontend/lib/pages/store_page.dart`）
  - 积分卡升级：品牌化渐变主卡 + `PAIR REWARD` 标签
  - 分区标题统一为左侧色条 + 副标题说明
  - 商品/我发布/已兑换记录改为统一卡片体系，减少原生 `ListTile` 观感
  - 错误与空态改为专用提示面板（不再生硬文本行）
- 保持原有加载策略：仅列表数据使用骨架屏，页面结构始终可见

## Codex UI 全局统一补充（2026-03-09）
- 已更新全局主题：`frontend/lib/ui/app_theme.dart`
  - 统一 AppBar 标题字重与尺寸
  - 统一 FilledButton、Chip、InputDecoration 风格（圆角/边框/字号）
  - 统一焦点与错误边框行为，减少页面间风格漂移
- 已更新入口页与底栏：`frontend/lib/main.dart`
  - 模式选择页视觉强化（品牌胶囊标签、卡片边框与留白）
  - 底部导航重构为渐变容器 + 选中态描边，降低原生默认感
- 验证：`flutter analyze` 通过（No issues found）

## Codex UI 第三轮优化（2026-03-09）
- 已完成通知页重构：`frontend/lib/pages/notifications_page.dart`
  - 顶部摘要 Hero 升级（未读/总数指标）
  - 通知项改为卡片化结构（类型标签、正文层级、时间与动作区）
  - 错误与空态改为专用提示面板
  - 保持“仅列表使用骨架屏”的加载策略
- 已完成个人页重构：`frontend/lib/pages/profile_page.dart`
  - 顶部资料卡升级为品牌化渐变视觉，统一与首页/商城语义
  - 分区标题统一为左侧色条 + 副标题
  - 功能项与开关项统一卡片样式
  - 双人模式设置失败由静默吞错改为 Snackbar 可见提示
- 验证：`flutter analyze` 通过（No issues found）

## Codex UI 第四轮优化（2026-03-09）
- 已完成编辑任务页重构：`frontend/lib/pages/edit_task_page.dart`
  - 表单分区卡片化：基础信息 / 截止设置 / 重复规则
  - 截止与重复截止改为信息行 + 操作按钮，语义更清晰

## Codex UI 第五轮优化（2026-03-09）
- 已新增通用 Hero 组件：`frontend/lib/widgets/hero_panel.dart`
  - 统一结构为：顶部标签 + 主标题 + 副标题（可选）+ 指标行
  - 统一圆角、渐变、阴影与指标卡视觉节奏
- 已完成四大主页面 Hero 对齐：
  - `frontend/lib/pages/home_page.dart`
  - `frontend/lib/pages/store_page.dart`
  - `frontend/lib/pages/notifications_page.dart`
  - `frontend/lib/pages/profile_page.dart`
- 本轮效果：四页首屏信息区布局与层级一致，内容语义按页面保留差异
- 验证：`flutter analyze` 通过（No issues found）

## Codex UI 第六轮优化（2026-03-09）
- 主题色收敛：
  - `frontend/lib/ui/app_theme.dart` 将强调色 `blush` 从高饱和粉色改为低饱和蓝色，统一简约浅色基调
  - 页面背景中间层与底层色值改为更中性的浅灰蓝过渡，降低“糖果感”
- 底部导航继续对齐 Play 结构细节：
  - `frontend/lib/main.dart` 为 `NavigationBar` 增加 `surfaceTintColor/shadowColor` 透明化处理
  - 维持“无选中边框/无胶囊高亮”，仅通过图标与文字状态变化表达选中
  - 增加 `selectedIcon` 两态图标（任务/商城/通知/个人）
  - 底栏最后一项文案由“我的”改为“个人”
- 验证：`flutter analyze` 通过（No issues found）

## Codex UI 第七轮优化（2026-03-09）
- 首页细节收敛：`frontend/lib/pages/home_page.dart`
  - 列表工具条改为“状态/排序摘要 + 调整”轻量结构，减少彩色 chip 堆叠
  - 任务卡片操作区由右侧双按钮改为 `more` 菜单（编辑/删除），降低视觉噪声
  - 任务卡支持展示备注摘要（最多两行），信息层次更清晰
  - 分区标题从粗色条调整为小圆点标识，整体更简约
  - 任务卡阴影与面板透明度微调，提升层次但不厚重
- 验证：`flutter analyze` 通过（No issues found）

## Codex UI 第八轮优化（2026-03-09）
- 商城页细节收敛：`frontend/lib/pages/store_page.dart`
  - “发布商品”入口从底部 FAB 改为 AppBar 右上角 `发布` 文本按钮
  - 分区标题样式与首页统一为小圆点标识，弱化厚重色条
  - 商品卡片与兑换记录卡补充轻阴影，提升层次但保持简约
  - 商品信息 chip 配色降低饱和度，减少紫色强调
  - “我发布的商品”操作改为 `more` 菜单（编辑/下架），减少按钮堆叠
- 验证：`flutter analyze` 通过（No issues found）
  - 保留原有重复任务、周几重复、共同任务字段与保存逻辑
- 已完成调试页重构：`frontend/lib/pages/debug_page.dart`
  - 顶部诊断 Hero：Base URL / 健康状态 / 日志数
  - 诊断操作区重构：运行诊断 + 清空日志
  - 日志展示增强：错误日志高亮、卡片化可选中文本
- 验证：`flutter analyze` 通过（No issues found）

## Codex UI 第五轮优化（2026-03-09）
- 已完成弹窗视觉统一：
  - 商城页 `发布商品 / 编辑商品 / 下架确认` 统一改为共用弹窗模板
  - 个人页 `编辑昵称` 改为统一弹窗模板
- 商城页新增复用弹窗组件方法：
  - `_showProductFormDialog` / `_showConfirmDialog` / `_buildDialogShell` / `_dialogField`
- 弹窗统一策略：
  - 标题 + 副标题结构
  - 统一圆角、内边距、按钮层级
  - 输入项与说明文字间距统一
- 验证：`flutter analyze` 通过（No issues found）

## Codex UI 第六轮优化（2026-03-09）
- 四个主页面 AppBar 已统一为 `状态图标 + 标题`：
  - Home / Store / Notifications / Profile
  - 指示器仅图标无文字，状态语义：灰=检测中、绿=在线、红=离线/异常
- 新增并启用统一浅色语义色体系：`frontend/lib/ui/app_theme.dart`
  - 页面背景、面板、边框、柔和标签色、错误/警告底色与边框、Hero 色
- 核心页面已批量去除分散硬编码色并收敛到主题变量：
  - `main.dart`
  - `home_page.dart`
  - `store_page.dart`
  - `notifications_page.dart`
  - `profile_page.dart`
  - `edit_task_page.dart`
  - `debug_page.dart`
- 验证：`flutter analyze` 通过（No issues found）

## Codex UI 收尾交付（2026-03-09）
- 已新增 UI 收尾文档：`docs/UI_CURRENT_STATE_AND_NEXT.md`
  - 汇总当前 UI 已完成项（可交付）
  - 明确当前视觉基线（浅色、低饱和、统一 token）
  - 收敛后续优化为 3 项（动效/字体层级/空状态）
  - 建议 UI 冻结为 `v1-beta`，避免后端联调阶段反复改布局
