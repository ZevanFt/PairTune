# PairTune 组件库使用指南

> 更新时间：2026-04-19
> 版本：v1.0

---

## 一、使用原则

### 1.1 核心原则

```
❌ 禁止内联创建重复UI
✅ 必须使用统一组件库
✅ 通过参数控制变体
✅ 不创建新组件
```

### 1.2 导入方式

```dart
import '../widgets/app_components.dart';
```

---

## 二、页面框架

### 2.1 AppPage

统一页面脚手架，所有页面必须使用。

```dart
AppPage(
  appBar: AppBar(title: const Text('标题')),
  children: [
    // 页面内容
  ],
  onRefresh: () async {
    // 下拉刷新
  },
)
```

**参数说明：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| children | List<Widget> | ✅ | 页面内容 |
| appBar | PreferredSizeWidget | ❌ | 顶部栏 |
| padding | EdgeInsets | ❌ | 内边距，默认16 |
| onRefresh | Function | ❌ | 下拉刷新 |
| fab | Widget | ❌ | 悬浮按钮 |
| bottomNav | Widget | ❌ | 底部导航 |

---

## 三、卡片组件

### 3.1 AppCard

统一卡片，所有卡片必须使用。

```dart
AppCard(
  child: Text('内容'),
  onTap: () {
    // 点击事件
  },
)
```

**参数说明：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| child | Widget | ✅ | 卡片内容 |
| padding | EdgeInsets | ❌ | 内边距，默认16 |
| margin | EdgeInsets | ❌ | 外边距 |
| onTap | VoidCallback | ❌ | 点击事件 |
| borderColor | Color | ❌ | 边框颜色 |

### 3.2 AppListCard

列表项卡片，用于列表项。

```dart
AppListCard(
  title: '标题',
  subtitle: '描述',
  leading: Icon(Icons.star),
  trailing: Icon(Icons.chevron_right),
  onTap: () {},
)
```

---

## 四、按钮组件

### 4.1 AppPrimaryButton

主要按钮，用于主要操作。

```dart
AppPrimaryButton(
  label: '保存',
  icon: Icons.save,
  onPressed: () {},
)
```

### 4.2 AppSecondaryButton

次要按钮，用于次要操作。

```dart
AppSecondaryButton(
  label: '取消',
  onPressed: () {},
)
```

### 4.3 AppTextButton

文字按钮，用于链接式操作。

```dart
AppTextButton(
  label: '查看更多',
  onPressed: () {},
)
```

---

## 五、标签组件

### 5.1 AppTag

统一标签。

```dart
AppTag(
  label: '紧急',
  color: AppTheme.danger,
  icon: Icons.warning,
)
```

### 5.2 AppQuadrantTag

四象限标签。

```dart
AppQuadrantTag(quadrant: TaskQuadrant.importantUrgent)
```

---

## 六、分隔组件

### 6.1 AppSectionHeader

区块标题。

```dart
AppSectionHeader(
  title: '任务列表',
  subtitle: '按条件筛选',
  action: TextButton(child: Text('查看全部')),
)
```

### 6.2 AppDivider

分隔线。

```dart
AppDivider()
```

---

## 七、状态组件

### 7.1 AppEmptyState

空状态。

```dart
AppEmptyState(
  icon: Icons.inbox_outlined,
  message: '暂无任务',
  action: AppPrimaryButton(label: '新建', onPressed: () {}),
)
```

### 7.2 AppLoadingState

加载状态。

```dart
AppLoadingState(message: '加载中...')
```

### 7.3 AppErrorState

错误状态。

```dart
AppErrorState(
  message: '加载失败',
  onRetry: () {},
)
```

---

## 八、输入组件

### 8.1 AppTextField

统一输入框。

```dart
AppTextField(
  controller: _controller,
  label: '标题',
  hint: '请输入标题',
  prefixIcon: Icons.title,
)
```

---

## 九、完整示例

### 9.1 任务列表页面

```dart
class TaskListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppPage(
      appBar: AppBar(title: const Text('任务')),
      children: [
        // Hero卡片
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('今日概览', style: AppText.heading2),
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  Text('5', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                  const SizedBox(width: AppSpace.sm),
                  Text('个待办', style: AppText.caption),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),

        // 区块标题
        AppSectionHeader(title: '任务列表', subtitle: '按条件筛选'),

        // 任务列表
        AppListCard(
          title: '完成项目报告',
          subtitle: '截止: 今天 18:00',
          leading: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.urgentImportant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          trailing: AppQuadrantTag(quadrant: TaskQuadrant.importantUrgent),
          onTap: () {},
        ),

        AppListCard(
          title: '回复邮件',
          subtitle: '截止: 明天 12:00',
          trailing: AppQuadrantTag(quadrant: TaskQuadrant.importantNotUrgent),
          onTap: () {},
        ),

        // 空状态
        AppEmptyState(
          icon: Icons.check_circle_outline,
          message: '暂无任务，点击 + 新建',
        ),
      ],
      onRefresh: () async {
        // 刷新数据
      },
    );
  }
}
```

---

## 十、禁止事项

### 10.1 禁止内联创建卡片

```dart
// ❌ 错误
Container(
  decoration: BoxDecoration(
    color: AppTheme.surface,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppTheme.border),
  ),
  child: Text('内容'),
)

// ✅ 正确
AppCard(child: Text('内容'))
```

### 10.2 禁止内联创建按钮

```dart
// ❌ 错误
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primary,
  ),
  child: Text('保存'),
  onPressed: () {},
)

// ✅ 正确
AppPrimaryButton(label: '保存', onPressed: () {})
```

### 10.3 禁止内联创建标签

```dart
// ❌ 错误
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: color.withOpacity(0.1),
    borderRadius: BorderRadius.circular(6),
  ),
  child: Text('标签'),
)

// ✅ 正确
AppTag(label: '标签', color: color)
```

---

*文档结束*
