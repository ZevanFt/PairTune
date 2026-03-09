import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/task_db.dart';
import '../models/task_item.dart';
import '../services/health_api_service.dart';
import '../services/store_api_service.dart';
import '../services/task_api_service.dart';
import '../ui/app_theme.dart';
import '../utils/error_display.dart';
import '../widgets/shimmer_block.dart';
import 'edit_task_page.dart';

enum TaskFilterType { all, active, done }

enum TaskSortType { updatedDesc, dueAsc, pointsDesc }

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.owner,
    required this.duoEnabled,
    required this.onOwnerChanged,
  });

  final String owner;
  final bool duoEnabled;
  final ValueChanged<String> onOwnerChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _db = TaskDb.instance;
  final _api = TaskApiService();
  final _store = StoreApiService();
  final _healthApi = HealthApiService();
  List<TaskItem> _tasks = [];
  bool _loading = true;
  bool _refreshing = false;
  String? _banner;
  BackendHealthStatus? _healthStatus;
  TaskFilterType _filter = TaskFilterType.active;
  TaskSortType _sort = TaskSortType.updatedDesc;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.owner != widget.owner) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      if (_tasks.isEmpty) {
        _loading = true;
      } else {
        _refreshing = true;
      }
    });
    List<TaskItem> tasks;
    try {
      tasks = await _api.listTasks(widget.owner);
      _banner = null;
    } catch (e) {
      tasks = await _db.listTasks();
      _banner = '${formatErrorMessage(e)}，已切换本地 SQLite';
    }
    await _refreshHealth();
    setState(() {
      _tasks = tasks;
      _loading = false;
      _refreshing = false;
    });
  }

  Future<void> _refreshHealth() async {
    final status = await _healthApi.checkHealth();
    if (!mounted) return;
    setState(() => _healthStatus = status);
  }

  Future<void> _addTask([TaskQuadrant? quadrant]) async {
    final created = await Navigator.push<TaskItem>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditTaskPage(initialQuadrant: quadrant, currentOwner: widget.owner),
      ),
    );
    if (created != null) {
      try {
        await _api.createTask(created, widget.owner);
        _banner = null;
      } catch (e) {
        await _db.insertTask(created);
        _banner = '${formatErrorMessage(e)}，任务已保存到本地 SQLite';
      }
      await _load();
    }
  }

  Future<void> _toggle(TaskItem task, bool done) async {
    TaskItem updated;
    if (task.taskType == TaskType.shared) {
      final nextDoneByMe = widget.owner == 'me' ? done : task.doneByMe;
      final nextDoneByPartner = widget.owner == 'partner'
          ? done
          : task.doneByPartner;
      final nextIsDone = task.completionMode == TaskCompletionMode.allRequired
          ? (nextDoneByMe && nextDoneByPartner)
          : (nextDoneByMe || nextDoneByPartner);
      updated = task.copyWith(
        doneByMe: nextDoneByMe,
        doneByPartner: nextDoneByPartner,
        isDone: nextIsDone,
      );
    } else {
      updated = task.copyWith(isDone: done);
    }
    try {
      await _api.updateTask(updated, widget.owner);
      if (!task.isDone && done && task.points > 0) {
        await _store.adjustPoints(
          owner: widget.owner,
          amount: task.points,
          reason: '完成任务:${task.title}',
        );
      }
      _banner = null;
    } catch (e) {
      await _db.updateTask(updated);
      _banner = '${formatErrorMessage(e)}，任务状态已更新到本地 SQLite';
    }
    await _load();
  }

  Future<void> _editTask(TaskItem task) async {
    final edited = await Navigator.push<TaskItem>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditTaskPage(initialTask: task, currentOwner: widget.owner),
      ),
    );
    if (edited == null) return;
    try {
      await _api.updateTask(edited, widget.owner);
      _banner = null;
    } catch (e) {
      await _db.updateTask(edited);
      _banner = '${formatErrorMessage(e)}，任务编辑已保存到本地 SQLite';
    }
    await _load();
  }

  Future<void> _delete(TaskItem task) async {
    if (task.id == null) return;
    try {
      await _api.deleteTask(task.id!, widget.owner);
      _banner = null;
    } catch (e) {
      await _db.deleteTask(task.id!);
      _banner = '${formatErrorMessage(e)}，任务已从本地 SQLite 删除';
    }
    await _load();
  }

  int _countByQuadrant(TaskQuadrant quadrant) {
    return _tasks.where((t) => t.quadrant == quadrant && !t.isDone).length;
  }

  List<TaskItem> get _displayTasks {
    final list = _tasks.where((task) {
      switch (_filter) {
        case TaskFilterType.all:
          return true;
        case TaskFilterType.active:
          return !task.isDone;
        case TaskFilterType.done:
          return task.isDone;
      }
    }).toList();

    list.sort((a, b) {
      switch (_sort) {
        case TaskSortType.updatedDesc:
          return b.updatedAt.compareTo(a.updatedAt);
        case TaskSortType.dueAsc:
          final aDue = a.dueDate;
          final bDue = b.dueDate;
          if (aDue == null && bDue == null) return 0;
          if (aDue == null) return 1;
          if (bDue == null) return -1;
          return aDue.compareTo(bDue);
        case TaskSortType.pointsDesc:
          return b.points.compareTo(a.points);
      }
    });

    return list;
  }

  String _filterLabel(TaskFilterType filter) {
    switch (filter) {
      case TaskFilterType.all:
        return '全部';
      case TaskFilterType.active:
        return '未完成';
      case TaskFilterType.done:
        return '已完成';
    }
  }

  String _sortLabel(TaskSortType sort) {
    switch (sort) {
      case TaskSortType.updatedDesc:
        return '最近更新';
      case TaskSortType.dueAsc:
        return '截止日期';
      case TaskSortType.pointsDesc:
        return '积分高到低';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _tasks.where((task) => !task.isDone).length;
    final doneCount = _tasks.where((task) => task.isDone).length;
    final completionRate = _tasks.isEmpty
        ? 0
        : ((doneCount / _tasks.length) * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: _buildTitleWithHealth(widget.duoEnabled ? '要事第一' : '单人任务'),
        actions: [
          if (widget.duoEnabled)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'me', label: Text('我')),
                  ButtonSegment(value: 'partner', label: Text('搭档')),
                ],
                selected: {widget.owner},
                onSelectionChanged: (value) {
                  widget.onOwnerChanged(value.first);
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        label: const Text('新建任务'),
        icon: const Icon(Icons.add_rounded),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.pageBgTop, AppTheme.pageBgMid, AppTheme.pageBgBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHero(
                activeCount: activeCount,
                doneCount: doneCount,
                completionRate: completionRate,
              ),
              const SizedBox(height: 14),
              if (_refreshing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (_banner != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildWarnBanner(_banner!),
                ),
              _buildSectionHeader('四象限', '点击象限即可快速加任务'),
              const SizedBox(height: 8),
              _buildQuadrantGrid(),
              const SizedBox(height: 16),
              _buildSectionHeader('任务列表', '按状态和排序查看'),
              const SizedBox(height: 8),
              _buildListToolbar(),
              const SizedBox(height: 10),
              if (_loading && _tasks.isEmpty) ..._buildTaskSkeletons(),
              ..._displayTasks.map(_buildTaskTile),
              if (!_loading && _displayTasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(child: Text('暂无任务，点击右下角 + 新建')),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleWithHealth(String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHealthDot(),
        const SizedBox(width: 8),
        Text(title),
      ],
    );
  }

  Widget _buildHealthDot() {
    final status = _healthStatus;
    final online = status?.online == true;
    final color = status == null
        ? Colors.grey
        : (online ? AppTheme.success : AppTheme.danger);

    return Icon(
      Icons.circle,
      size: 11,
      color: color,
    );
  }

  Widget _buildWarnBanner(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.warnBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warnBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_tethering_error_rounded,
            size: 16,
            color: Color(0xFFA9641B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFA9641B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero({
    required int activeCount,
    required int doneCount,
    required int completionRate,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppTheme.heroStart, AppTheme.heroMid, AppTheme.heroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2B233861),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x2EFFFFFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'TODAY FOCUS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '完成率 $completionRate%',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            !widget.duoEnabled
                ? '今天把关键任务推进一步'
                : (widget.owner == 'me' ? '我今天要推进的重点' : '搭档今天的重点事项'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _heroMetric(
                icon: Icons.bolt_rounded,
                label: '进行中',
                value: '$activeCount',
              ),
              const SizedBox(width: 10),
              _heroMetric(
                icon: Icons.check_circle_rounded,
                label: '已完成',
                value: '$doneCount',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuadrantGrid() {
    final quadrants = [
      (
        q: TaskQuadrant.importantUrgent,
        icon: Icons.local_fire_department_rounded,
        bg: AppTheme.panel.withValues(alpha: 0.95),
        accent: const Color(0xFF2A3E6E),
      ),
      (
        q: TaskQuadrant.importantNotUrgent,
        icon: Icons.lightbulb_rounded,
        bg: AppTheme.panel.withValues(alpha: 0.95),
        accent: const Color(0xFF3F568A),
      ),
      (
        q: TaskQuadrant.notImportantUrgent,
        icon: Icons.flash_on_rounded,
        bg: AppTheme.panel.withValues(alpha: 0.95),
        accent: const Color(0xFF5E6D95),
      ),
      (
        q: TaskQuadrant.notImportantNotUrgent,
        icon: Icons.spa_rounded,
        bg: AppTheme.panel.withValues(alpha: 0.95),
        accent: const Color(0xFF7683A8),
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.26,
      children: quadrants
          .map((item) => _quadrantCard(item.q, item.icon, item.bg, item.accent))
          .toList(),
    );
  }

  List<Widget> _buildTaskSkeletons() {
    return List.generate(
      4,
      (index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerBlock(
          height: 96,
          base: index.isEven
              ? const Color(0xFFEAE5DD)
              : const Color(0xFFE4DFD6),
        ),
      ),
    );
  }

  Widget _buildListToolbar() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.panelBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _taskMetaChip('状态: ${_filterLabel(_filter)}', AppTheme.softBlue),
                _taskMetaChip('排序: ${_sortLabel(_sort)}', AppTheme.softViolet),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: _openViewOptionsSheet,
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: const Text('筛选'),
          ),
        ],
      ),
    );
  }

  Future<void> _openViewOptionsSheet() async {
    TaskFilterType nextFilter = _filter;
    TaskSortType nextSort = _sort;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '筛选与排序',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '设置任务列表展示方式',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 12),
                  const Text('状态', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TaskFilterType.values
                        .map(
                          (filter) => ChoiceChip(
                            label: Text(_filterLabel(filter)),
                            selected: nextFilter == filter,
                            onSelected: (_) =>
                                setSheetState(() => nextFilter = filter),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('排序', style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...TaskSortType.values.map(
                    (sort) => RadioListTile<TaskSortType>(
                      dense: true,
                      value: sort,
                      groupValue: nextSort,
                      contentPadding: EdgeInsets.zero,
                      title: Text(_sortLabel(sort)),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => nextSort = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('应用'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (applied == true && mounted) {
      setState(() {
        _filter = nextFilter;
        _sort = nextSort;
      });
    }
  }

  Widget _quadrantCard(
    TaskQuadrant quadrant,
    IconData icon,
    Color bg,
    Color accent,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _addTask(quadrant),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    quadrant.label,
                    style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '${_countByQuadrant(quadrant)}',
              style: TextStyle(
                color: accent,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            Text(
              '个待办',
              style: TextStyle(color: accent.withValues(alpha: 0.88), fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              '点击添加',
              style: TextStyle(color: accent.withValues(alpha: 0.7), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTile(TaskItem task) {
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

    final ownerDone = widget.owner == 'me' ? task.doneByMe : task.doneByPartner;
    final sharedProgress = task.taskType == TaskType.shared
        ? '共同进度 我:${task.doneByMe ? '已完成' : '未完成'} / 搭档:${task.doneByPartner ? '已完成' : '未完成'}'
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.panelBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _editTask(task),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.scale(
                scale: 1.05,
                child: Checkbox(
                  value: task.taskType == TaskType.shared ? ownerDone : task.isDone,
                  onChanged: (value) {
                    if (value != null) {
                      _toggle(task, value);
                    }
                  },
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        decoration: task.isDone ? TextDecoration.lineThrough : null,
                        color: task.isDone ? AppTheme.textMuted : AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _taskMetaChip(task.quadrant.label, const Color(0xFFE8EEFF)),
                        _taskMetaChip(dueText, const Color(0xFFFFF0DE)),
                        _taskMetaChip('积分 ${task.points}', AppTheme.softGreen),
                        _taskMetaChip(repeatText, AppTheme.softViolet),
                      ],
                    ),
                    if (sharedProgress != null) ...[
                      const SizedBox(height: 7),
                      Text(
                        sharedProgress,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _editTask(task),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _delete(task),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskMetaChip(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppTheme.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            color: AppTheme.blush,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ),
      ],
    );
  }

  String _formatWeeklyCustom(List<int> weekdays) {
    if (weekdays.isEmpty) return '每周指定日期';
    const names = {
      1: '周一',
      2: '周二',
      3: '周三',
      4: '周四',
      5: '周五',
      6: '周六',
      7: '周日',
    };
    final text = weekdays
        .map((d) => names[d] ?? '')
        .where((e) => e.isNotEmpty)
        .join('、');
    return text.isEmpty ? '每周指定日期' : text;
  }
}
