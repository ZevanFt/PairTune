import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/task_db.dart';
import '../models/backend_health.dart';
import '../models/task_item.dart';
import '../providers/api_providers.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../services/health_api_service.dart';
import '../services/store_api_service.dart';
import '../services/task_api_service.dart';
import '../ui/app_space.dart';
import '../ui/app_text.dart';
import '../ui/app_theme.dart';
import '../utils/error_display.dart';
import '../widgets/health_indicator.dart';
import '../widgets/loading_state.dart';
import '../widgets/section_header.dart';
import '../widgets/status_panel.dart';
import 'edit_task_page.dart';

enum TaskFilterType { all, active, done }
enum TaskSortType { updatedDesc, dueAsc, pointsDesc }

// ─── Task list provider ────────────────────────────────────────────────────

class TaskListState {
  const TaskListState({
    this.tasks = const [],
    this.loading = true,
    this.refreshing = false,
    this.banner,
    this.filter = TaskFilterType.active,
    this.sort = TaskSortType.updatedDesc,
  });

  final List<TaskItem> tasks;
  final bool loading;
  final bool refreshing;
  final String? banner;
  final TaskFilterType filter;
  final TaskSortType sort;

  TaskListState copyWith({
    List<TaskItem>? tasks,
    bool? loading,
    bool? refreshing,
    String? banner,
    TaskFilterType? filter,
    TaskSortType? sort,
  }) {
    return TaskListState(
      tasks: tasks ?? this.tasks,
      loading: loading ?? this.loading,
      refreshing: refreshing ?? this.refreshing,
      banner: banner ?? this.banner,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
    );
  }

  List<TaskItem> get displayTasks {
    final list = tasks.where((task) {
      switch (filter) {
        case TaskFilterType.all: return true;
        case TaskFilterType.active: return !task.isDone;
        case TaskFilterType.done: return task.isDone;
      }
    }).toList();

    list.sort((a, b) {
      switch (sort) {
        case TaskSortType.updatedDesc: return b.updatedAt.compareTo(a.updatedAt);
        case TaskSortType.dueAsc:
          final aDue = a.dueDate, bDue = b.dueDate;
          if (aDue == null && bDue == null) return 0;
          if (aDue == null) return 1;
          if (bDue == null) return -1;
          return aDue.compareTo(bDue);
        case TaskSortType.pointsDesc: return b.points.compareTo(a.points);
      }
    });
    return list;
  }
}

class TaskListNotifier extends StateNotifier<TaskListState> {
  TaskListNotifier(this._api, this._store, this._db, this._healthApi)
      : super(const TaskListState());

  final TaskApiService _api;
  final StoreApiService _store;
  final TaskDb _db;
  final HealthApiService _healthApi;

  BackendHealthStatus? healthStatus;

  Future<void> load(String owner) async {
    state = state.copyWith(
      loading: state.tasks.isEmpty,
      refreshing: state.tasks.isNotEmpty,
    );
    List<TaskItem> tasks;
    String? banner;
    try {
      tasks = await _api.listTasks(owner);
    } catch (e) {
      tasks = await _db.listTasks();
      banner = '${formatErrorMessage(e)}，已切换本地 SQLite';
    }
    final status = await _healthApi.checkHealth();
    healthStatus = status;
    state = state.copyWith(tasks: tasks, loading: false, refreshing: false, banner: banner);
  }

  Future<void> addTask(TaskItem item, String owner) async {
    try {
      await _api.createTask(item, owner);
    } catch (e) {
      await _db.insertTask(item);
      state = state.copyWith(banner: '${formatErrorMessage(e)}，任务已保存到本地');
    }
    await load(owner);
  }

  Future<void> toggleTask(TaskItem task, bool done, String owner) async {
    TaskItem updated;
    if (task.taskType == TaskType.shared) {
      final nextDoneByMe = owner == 'me' ? done : task.doneByMe;
      final nextDoneByPartner = owner == 'partner' ? done : task.doneByPartner;
      final nextIsDone = task.completionMode == TaskCompletionMode.allRequired
          ? (nextDoneByMe && nextDoneByPartner)
          : (nextDoneByMe || nextDoneByPartner);
      updated = task.copyWith(doneByMe: nextDoneByMe, doneByPartner: nextDoneByPartner, isDone: nextIsDone);
    } else {
      updated = task.copyWith(isDone: done);
    }
    try {
      await _api.updateTask(updated, owner);
      if (!task.isDone && done && task.points > 0) {
        await _store.adjustPoints(owner: owner, amount: task.points, reason: '完成任务:${task.title}');
      }
    } catch (e) {
      await _db.updateTask(updated);
      state = state.copyWith(banner: '${formatErrorMessage(e)}，任务状态已更新到本地');
    }
    await load(owner);
  }

  Future<void> updateTask(TaskItem task, String owner) async {
    try {
      await _api.updateTask(task, owner);
    } catch (e) {
      await _db.updateTask(task);
      state = state.copyWith(banner: '${formatErrorMessage(e)}，任务编辑已保存到本地');
    }
    await load(owner);
  }

  Future<void> deleteTask(TaskItem task, String owner) async {
    if (task.id == null) return;
    try {
      await _api.deleteTask(task.id!, owner);
    } catch (e) {
      await _db.deleteTask(task.id!);
      state = state.copyWith(banner: '${formatErrorMessage(e)}，任务已从本地删除');
    }
    await load(owner);
  }

  void setFilter(TaskFilterType filter) => state = state.copyWith(filter: filter);
  void setSort(TaskSortType sort) => state = state.copyWith(sort: sort);
}

final taskListProvider = StateNotifierProvider<TaskListNotifier, TaskListState>((ref) {
  return TaskListNotifier(
    ref.watch(taskApiProvider),
    ref.watch(storeApiProvider),
    TaskDb.instance,
    ref.watch(healthApiProvider),
  );
});

// ─── Home Page ─────────────────────────────────────────────────────────────

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _hideGuestBanner = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String get _owner => ref.read(appProvider).owner;
  bool get _duoEnabled => ref.read(appProvider).duoEnabled;
  bool get _isGuest => ref.read(isGuestProvider);

  void _load() => ref.read(taskListProvider.notifier).load(_owner);

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appProvider);
    final taskState = ref.watch(taskListProvider);
    final notifier = ref.read(taskListProvider.notifier);
    final healthStatus = notifier.healthStatus;

    final activeCount = taskState.tasks.where((t) => !t.isDone).length;
    final doneCount = taskState.tasks.where((t) => t.isDone).length;
    final completionRate = taskState.tasks.isEmpty ? 0 : ((doneCount / taskState.tasks.length) * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: TitleWithHealth(
          title: appState.duoEnabled ? '要事第一' : '单人任务',
          status: healthStatus ?? const BackendHealthStatus(online: false, statusCode: 0, statusText: '检查中'),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _addTask(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('新建'),
          ),
          const SizedBox(width: 4),
          if (appState.duoEnabled)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'me', label: Text('我')),
                  ButtonSegment(value: 'partner', label: Text('搭档')),
                ],
                selected: {appState.owner},
                onSelectionChanged: (v) => ref.read(appProvider.notifier).setOwner(v.first),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifier.load(_owner),
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.lg),
          children: [
            if (_isGuest && !_hideGuestBanner) ...[
              GuestBanner(onExit: () => ref.read(authProvider.notifier).exitGuest()),
              const SizedBox(height: AppSpace.sm),
            ],
            _HeroCard(
              duoEnabled: appState.duoEnabled,
              owner: appState.owner,
              activeCount: activeCount,
              doneCount: doneCount,
              completionRate: completionRate,
            ),
            const SizedBox(height: AppSpace.md),
            if (taskState.refreshing)
              const Padding(padding: EdgeInsets.only(bottom: 12), child: LinearProgressIndicator(minHeight: 2)),
            if (taskState.banner != null)
              Padding(padding: const EdgeInsets.only(bottom: 12), child: WarnPanel(message: taskState.banner!)),
            const SectionHeader(title: '四象限', subtitle: '点击象限快速创建任务'),
            const SizedBox(height: AppSpace.sm),
            _QuadrantGrid(
              tasks: taskState.tasks,
              onTap: (q) => _addTask(q),
            ),
            const SizedBox(height: AppSpace.lg),
            const SectionHeader(title: '任务列表', subtitle: '按条件筛选并专注执行'),
            const SizedBox(height: AppSpace.sm),
            _ListToolbar(
              filter: taskState.filter,
              sort: taskState.sort,
              onOpenOptions: () => _openViewOptionsSheet(taskState),
            ),
            const SizedBox(height: AppSpace.sm),
            if (taskState.loading && taskState.tasks.isEmpty)
              const LoadingState()
            else if (taskState.displayTasks.isEmpty)
              const EmptyState(icon: Icons.check_circle_outline_rounded, message: '暂无任务，点击 + 新建')
            else
              ...taskState.displayTasks.map((t) => _TaskTile(
                    task: t,
                    owner: appState.owner,
                    onToggle: (done) => notifier.toggleTask(t, done, _owner),
                    onEdit: () => _editTask(t),
                    onDelete: () => notifier.deleteTask(t, _owner),
                  )),
          ],
        ),
      ),
    );
  }

  Future<void> _addTask([TaskQuadrant? quadrant]) async {
    final created = await Navigator.push<TaskItem>(
      context,
      MaterialPageRoute(builder: (_) => EditTaskPage(initialQuadrant: quadrant, currentOwner: _owner)),
    );
    if (created != null) {
      await ref.read(taskListProvider.notifier).addTask(created, _owner);
    }
  }

  Future<void> _editTask(TaskItem task) async {
    final edited = await Navigator.push<TaskItem>(
      context,
      MaterialPageRoute(builder: (_) => EditTaskPage(initialTask: task, currentOwner: _owner)),
    );
    if (edited != null) {
      await ref.read(taskListProvider.notifier).updateTask(edited, _owner);
    }
  }

  Future<void> _openViewOptionsSheet(TaskListState current) async {
    TaskFilterType nextFilter = current.filter;
    TaskSortType nextSort = current.sort;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('筛选与排序', style: AppText.title3),
                const SizedBox(height: 4),
                Text('设置任务列表展示方式', style: AppText.footnote.copyWith(color: AppTheme.textMuted)),
                const SizedBox(height: 16),
                Text('状态', style: AppText.headline),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TaskFilterType.values.map((f) => ChoiceChip(
                    label: Text(_filterLabel(f)),
                    selected: nextFilter == f,
                    onSelected: (_) => setSheetState(() => nextFilter = f),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                Text('排序', style: AppText.headline),
                const SizedBox(height: 8),
                ...TaskSortType.values.map((s) => RadioListTile<TaskSortType>(
                  dense: true,
                  value: s,
                  groupValue: nextSort,
                  contentPadding: EdgeInsets.zero,
                  title: Text(_sortLabel(s)),
                  onChanged: (v) { if (v != null) setSheetState(() => nextSort = v); },
                )),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('应用')),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (applied == true && mounted) {
      final notifier = ref.read(taskListProvider.notifier);
      notifier.setFilter(nextFilter);
      notifier.setSort(nextSort);
    }
  }

  static String _filterLabel(TaskFilterType f) => switch (f) {
    TaskFilterType.all => '全部',
    TaskFilterType.active => '未完成',
    TaskFilterType.done => '已完成',
  };

  static String _sortLabel(TaskSortType s) => switch (s) {
    TaskSortType.updatedDesc => '最近更新',
    TaskSortType.dueAsc => '截止日期',
    TaskSortType.pointsDesc => '积分高到低',
  };
}

// ─── Hero Card ─────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.duoEnabled,
    required this.owner,
    required this.activeCount,
    required this.doneCount,
    required this.completionRate,
  });

  final bool duoEnabled;
  final String owner;
  final int activeCount;
  final int doneCount;
  final int completionRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppTheme.heroGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.shadowLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: const Text(
              'TODAY FOCUS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 标题
          Text(
            !duoEnabled ? '今天把关键任务推进一步' : (owner == 'me' ? '我今天要推进的重点' : '搭档今天的重点事项'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          // 统计数据
          Row(
            children: [
              _buildStatItem(Icons.play_arrow_rounded, '进行中', activeCount),
              const SizedBox(width: 24),
              _buildStatItem(Icons.check_circle_rounded, '已完成', doneCount),
              const Spacer(),
              // 完成率圆环
              Column(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: completionRate / 100,
                          strokeWidth: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                        Text(
                          '$completionRate',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '完成率',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }
}

// ─── Quadrant Grid ─────────────────────────────────────────────────────────

class _QuadrantData {
  const _QuadrantData({
    required this.q,
    required this.icon,
    required this.color,
    required this.label,
    required this.desc,
  });
  final TaskQuadrant q;
  final IconData icon;
  final Color color;
  final String label;
  final String desc;
}

class _QuadrantGrid extends StatelessWidget {
  const _QuadrantGrid({required this.tasks, required this.onTap});

  final List<TaskItem> tasks;
  final void Function(TaskQuadrant) onTap;

  @override
  Widget build(BuildContext context) {
    // 使用新的四象限色彩
    final quadrants = [
      _QuadrantData(
        q: TaskQuadrant.importantUrgent,
        icon: Icons.local_fire_department_rounded,
        color: AppTheme.urgentImportant,
        label: '紧急重要',
        desc: '立即执行',
      ),
      _QuadrantData(
        q: TaskQuadrant.importantNotUrgent,
        icon: Icons.lightbulb_rounded,
        color: AppTheme.importantNotUrgent,
        label: '重要不紧急',
        desc: '规划执行',
      ),
      _QuadrantData(
        q: TaskQuadrant.notImportantUrgent,
        icon: Icons.flash_on_rounded,
        color: AppTheme.urgentNotImportant,
        label: '紧急不重要',
        desc: '委托处理',
      ),
      _QuadrantData(
        q: TaskQuadrant.notImportantNotUrgent,
        icon: Icons.spa_rounded,
        color: AppTheme.notUrgentNotImportant,
        label: '不紧急不重要',
        desc: '稍后处理',
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpace.md,
      mainAxisSpacing: AppSpace.md,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: quadrants.map((item) => _buildQuadrantCard(item)).toList(),
    );
  }

  int _count(TaskQuadrant q) => tasks.where((t) => t.quadrant == q && !t.isDone).length;

  Widget _buildQuadrantCard(_QuadrantData item) {
    final count = _count(item.q);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: () => onTap(item.q),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: item.color.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图标和标签
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(item.icon, size: 16, color: item.color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        color: item.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // 数量
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      color: item.color,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '个待办',
                      style: TextStyle(
                        color: item.color.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.desc,
                style: TextStyle(
                  color: item.color.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── List Toolbar ──────────────────────────────────────────────────────────

class _ListToolbar extends StatelessWidget {
  const _ListToolbar({required this.filter, required this.sort, required this.onOpenOptions});

  final TaskFilterType filter;
  final TaskSortType sort;
  final VoidCallback onOpenOptions;

  static String _fl(TaskFilterType f) => switch (f) { TaskFilterType.all => '全部', TaskFilterType.active => '未完成', TaskFilterType.done => '已完成' };
  static String _sl(TaskSortType s) => switch (s) { TaskSortType.updatedDesc => '最近更新', TaskSortType.dueAsc => '截止日期', TaskSortType.pointsDesc => '积分高到低' };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('状态 ${_fl(filter)} · 排序 ${_sl(sort)}', style: AppText.footnote.copyWith(fontWeight: FontWeight.w600)),
          ),
          TextButton.icon(
            onPressed: onOpenOptions,
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: const Text('调整'),
          ),
        ],
      ),
    );
  }
}

// ─── Task Tile ─────────────────────────────────────────────────────────────

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.owner,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final TaskItem task;
  final String owner;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dueText = task.dueDate == null
        ? '无截止'
        : (task.dueMode == TaskDueMode.time
            ? DateFormat('MM-dd HH:mm').format(task.dueDate!)
            : '${DateFormat('MM-dd').format(task.dueDate!)} 23:59');
    final repeatText = task.repeatType == TaskRepeatType.none
        ? '不重复'
        : (task.repeatType == TaskRepeatType.weeklyCustom
            ? _formatWeeklyCustom(task.repeatWeekdays)
            : '${task.repeatType.label}${task.repeatInterval > 1 ? ' x${task.repeatInterval}' : ''}');

    final ownerDone = owner == 'me' ? task.doneByMe : task.doneByPartner;
    final sharedProgress = task.taskType == TaskType.shared
        ? '共同进度 我:${task.doneByMe ? "已完成" : "未完成"} / 搭档:${task.doneByPartner ? "已完成" : "未完成"}'
        : null;

    // 根据象限获取颜色
    final quadrantColor = _getQuadrantColor(task.quadrant);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpace.sm),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 复选框
              Container(
                margin: const EdgeInsets.only(top: 2),
                child: Checkbox(
                  value: task.taskType == TaskType.shared ? ownerDone : task.isDone,
                  onChanged: (v) { if (v != null) onToggle(v); },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题行
                    Row(
                      children: [
                        // 象限指示条
                        Container(
                          width: 3,
                          height: 18,
                          decoration: BoxDecoration(
                            color: quadrantColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              decoration: task.isDone ? TextDecoration.lineThrough : null,
                              color: task.isDone ? AppTheme.inkMuted : AppTheme.ink,
                            ),
                          ),
                        ),
                        // 更多按钮
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_horiz_rounded, size: 20, color: AppTheme.inkMuted),
                          onSelected: (v) { if (v == 'edit') onEdit(); else if (v == 'delete') onDelete(); },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
                                  const SizedBox(width: 12),
                                  const Text('编辑'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18, color: AppTheme.danger),
                                  const SizedBox(width: 12),
                                  const Text('删除'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // 备注
                    if (task.note != null && task.note!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        task.note!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyMuted(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    // 标签
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildChip(task.quadrant.label, quadrantColor),
                        _buildChip(dueText, AppTheme.warning),
                        if (task.points > 0) _buildChip('+${task.points}积分', AppTheme.success),
                        if (task.repeatType != TaskRepeatType.none) _buildChip(repeatText, AppTheme.primary),
                      ],
                    ),
                    // 共同任务进度
                    if (sharedProgress != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.softPrimary,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Text(
                          sharedProgress,
                          style: TextStyle(fontSize: 12, color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getQuadrantColor(TaskQuadrant q) {
    switch (q) {
      case TaskQuadrant.importantUrgent:
        return AppTheme.urgentImportant;
      case TaskQuadrant.importantNotUrgent:
        return AppTheme.importantNotUrgent;
      case TaskQuadrant.notImportantUrgent:
        return AppTheme.urgentNotImportant;
      case TaskQuadrant.notImportantNotUrgent:
        return AppTheme.notUrgentNotImportant;
    }
  }

  Widget _buildChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _formatWeeklyCustom(List<int> weekdays) {
    if (weekdays.isEmpty) return '每周指定日期';
    const names = {1: '周一', 2: '周二', 3: '周三', 4: '周四', 5: '周五', 6: '周六', 7: '周日'};
    final text = weekdays.map((d) => names[d] ?? '').where((e) => e.isNotEmpty).join('、');
    return text.isEmpty ? '每周指定日期' : text;
  }
}
