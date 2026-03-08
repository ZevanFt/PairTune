import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task_item.dart';
import '../ui/app_theme.dart';
import '../widgets/custom_date_picker.dart';

class EditTaskPage extends StatefulWidget {
  const EditTaskPage({
    super.key,
    this.initialQuadrant,
    this.initialTask,
    this.currentOwner = 'me',
  });

  final TaskQuadrant? initialQuadrant;
  final TaskItem? initialTask;
  final String currentOwner;

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  static const _weekdayOptions = [
    (1, '周一'),
    (2, '周二'),
    (3, '周三'),
    (4, '周四'),
    (5, '周五'),
    (6, '周六'),
    (7, '周日'),
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _pointsController = TextEditingController();
  final _repeatIntervalController = TextEditingController();

  late TaskQuadrant _quadrant;
  late TaskDueMode _dueMode;
  late TaskRepeatType _repeatType;
  late TaskType _taskType;
  late TaskCompletionMode _completionMode;
  DateTime? _dueDate;
  DateTime? _repeatUntil;
  Set<int> _repeatWeekdays = <int>{};

  @override
  void initState() {
    super.initState();
    final initialTask = widget.initialTask;
    _quadrant =
        initialTask?.quadrant ??
        widget.initialQuadrant ??
        TaskQuadrant.importantUrgent;
    _titleController.text = initialTask?.title ?? '';
    _noteController.text = initialTask?.note ?? '';
    _pointsController.text = (initialTask?.points ?? 0) == 0
        ? ''
        : '${initialTask!.points}';
    _dueMode = initialTask?.dueMode ?? TaskDueMode.day;
    _repeatType = initialTask?.repeatType ?? TaskRepeatType.none;
    _taskType = initialTask?.taskType ?? TaskType.personal;
    _completionMode = initialTask?.completionMode ?? TaskCompletionMode.anyOne;
    _repeatIntervalController.text = '${initialTask?.repeatInterval ?? 1}';
    _dueDate = initialTask?.dueDate;
    _repeatUntil = initialTask?.repeatUntil;
    _repeatWeekdays = Set<int>.from(
      initialTask?.repeatWeekdays ?? const <int>[],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _pointsController.dispose();
    _repeatIntervalController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await CustomDatePicker.show(
      context,
      initialDate: _dueDate ?? now,
      minDate: DateTime(now.year - 1),
      maxDate: DateTime(now.year + 5, 12, 31),
      title: '选择截止日期',
    );
    if (picked != null) {
      final base = _dueDate ?? DateTime.now();
      if (_dueMode == TaskDueMode.day) {
        setState(
          () => _dueDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            23,
            59,
            59,
            999,
          ),
        );
      } else {
        setState(
          () => _dueDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            base.hour,
            base.minute,
          ),
        );
      }
    }
  }

  Future<void> _pickDueTime() async {
    final now = DateTime.now();
    final current = _dueDate ?? now;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked != null) {
      setState(() {
        _dueMode = TaskDueMode.time;
        final base = _dueDate ?? DateTime(now.year, now.month, now.day);
        _dueDate = DateTime(
          base.year,
          base.month,
          base.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _pickRepeatUntilDate() async {
    final now = DateTime.now();
    final picked = await CustomDatePicker.show(
      context,
      initialDate: _repeatUntil ?? _dueDate ?? now,
      minDate: DateTime(now.year - 1),
      maxDate: DateTime(now.year + 10, 12, 31),
      title: '选择重复截止日期',
    );
    if (picked != null) {
      setState(
        () => _repeatUntil = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
          999,
        ),
      );
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final points = int.tryParse(_pointsController.text.trim()) ?? 0;
    final inputInterval =
        int.tryParse(_repeatIntervalController.text.trim()) ?? 1;
    final repeatInterval = _repeatType == TaskRepeatType.weeklyCustom
        ? 1
        : (inputInterval <= 0 ? 1 : inputInterval);
    final repeatWeekdays = _repeatType == TaskRepeatType.weeklyCustom
        ? (_repeatWeekdays.toList()..sort())
        : <int>[];

    if (_repeatType == TaskRepeatType.weeklyCustom && _repeatWeekdays.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择每周重复日期')));
      return;
    }

    Navigator.pop(
      context,
      TaskItem(
        id: widget.initialTask?.id,
        title: _titleController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        quadrant: _quadrant,
        points: points,
        dueDate: _dueDate,
        dueMode: _dueMode,
        repeatType: _repeatType,
        repeatInterval: repeatInterval,
        repeatWeekdays: repeatWeekdays,
        repeatUntil: _repeatType == TaskRepeatType.none ? null : _repeatUntil,
        taskType: _taskType,
        completionMode: _completionMode,
        doneByMe: widget.initialTask?.doneByMe ?? (widget.currentOwner == 'me'),
        doneByPartner:
            widget.initialTask?.doneByPartner ??
            (widget.currentOwner == 'partner'),
        creator: widget.initialTask?.creator ?? widget.currentOwner,
        isDone: widget.initialTask?.isDone ?? false,
        createdAt: widget.initialTask?.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  String _dueDateText() {
    if (_dueDate == null) return '未设置截止日期';
    if (_dueMode == TaskDueMode.time) {
      return DateFormat('yyyy-MM-dd HH:mm').format(_dueDate!);
    }
    return '${DateFormat('yyyy-MM-dd').format(_dueDate!)} 当天 23:59';
  }

  String _repeatUntilText() {
    if (_repeatUntil == null) return '未设置（长期重复）';
    return DateFormat('yyyy-MM-dd').format(_repeatUntil!);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTask != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? '编辑任务' : '新建任务')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.pageBgTop, AppTheme.pageBgMid, AppTheme.pageBgBottom],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _buildSectionTitle('基础信息', '任务内容与象限归类'),
              const SizedBox(height: 8),
              _card(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: '任务标题'),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty) ? '请输入标题' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: '备注（可选）'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TaskQuadrant>(
                      value: _quadrant,
                      decoration: const InputDecoration(labelText: '四象限'),
                      items: TaskQuadrant.values
                          .map(
                            (q) => DropdownMenuItem(value: q, child: Text(q.label)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _quadrant = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TaskType>(
                      value: _taskType,
                      decoration: const InputDecoration(labelText: '任务类型'),
                      items: TaskType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _taskType = value);
                      },
                    ),
                    if (_taskType == TaskType.shared) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<TaskCompletionMode>(
                        value: _completionMode,
                        decoration: const InputDecoration(labelText: '共同任务完成方式'),
                        items: TaskCompletionMode.values
                            .map(
                              (mode) => DropdownMenuItem(
                                value: mode,
                                child: Text(mode.label),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _completionMode = value);
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pointsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '积分奖励（可选）'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildSectionTitle('截止设置', '支持当天截止或精确时间'),
              const SizedBox(height: 8),
              _card(
                child: Column(
                  children: [
                    SegmentedButton<TaskDueMode>(
                      showSelectedIcon: false,
                      segments: TaskDueMode.values
                          .map(
                            (mode) => ButtonSegment(
                              value: mode,
                              label: Text(mode.label),
                            ),
                          )
                          .toList(),
                      selected: {_dueMode},
                      onSelectionChanged: (set) {
                        final mode = set.first;
                        setState(() {
                          _dueMode = mode;
                          if (_dueDate != null && mode == TaskDueMode.day) {
                            _dueDate = DateTime(
                              _dueDate!.year,
                              _dueDate!.month,
                              _dueDate!.day,
                              23,
                              59,
                              59,
                              999,
                            );
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _infoRow(
                      title: '当前截止',
                      value: _dueDateText(),
                      actions: [
                        TextButton(onPressed: _pickDate, child: const Text('选择日期')),
                        if (_dueMode == TaskDueMode.time)
                          TextButton(
                            onPressed: _pickDueTime,
                            child: const Text('选择时间'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildSectionTitle('重复规则', '支持每天/每周/每月/每年与周几重复'),
              const SizedBox(height: 8),
              _card(
                child: Column(
                  children: [
                    DropdownButtonFormField<TaskRepeatType>(
                      value: _repeatType,
                      decoration: const InputDecoration(labelText: '重复规则'),
                      items: TaskRepeatType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _repeatType = value;
                            if (_repeatType == TaskRepeatType.none) {
                              _repeatUntil = null;
                              _repeatWeekdays = <int>{};
                              _repeatIntervalController.text = '1';
                            }
                          });
                        }
                      },
                    ),
                    if (_repeatType != TaskRepeatType.none) ...[
                      const SizedBox(height: 12),
                      if (_repeatType == TaskRepeatType.weeklyCustom) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '每周重复日期',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _weekdayOptions.map((entry) {
                            final selected = _repeatWeekdays.contains(entry.$1);
                            return FilterChip(
                              label: Text(entry.$2),
                              selected: selected,
                              onSelected: (value) {
                                setState(() {
                                  if (value) {
                                    _repeatWeekdays.add(entry.$1);
                                  } else {
                                    _repeatWeekdays.remove(entry.$1);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _repeatIntervalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: '重复间隔（整数）'),
                          validator: (value) {
                            if (_repeatType == TaskRepeatType.none ||
                                _repeatType == TaskRepeatType.weeklyCustom) {
                              return null;
                            }
                            final parsed = int.tryParse((value ?? '').trim()) ?? 0;
                            if (parsed <= 0) return '间隔必须大于 0';
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      _infoRow(
                        title: '重复截止',
                        value: _repeatUntilText(),
                        actions: [
                          TextButton(
                            onPressed: _pickRepeatUntilDate,
                            child: const Text('选择日期'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.check_rounded),
        label: const Text('保存任务'),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.panelBorder),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
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

  Widget _infoRow({
    required String title,
    required String value,
    required List<Widget> actions,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(spacing: 6, children: actions),
        ],
      ),
    );
  }
}
