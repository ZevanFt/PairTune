enum TaskQuadrant {
  importantUrgent,
  importantNotUrgent,
  notImportantUrgent,
  notImportantNotUrgent,
}

extension TaskQuadrantX on TaskQuadrant {
  String get label {
    switch (this) {
      case TaskQuadrant.importantUrgent:
        return '重要且紧急';
      case TaskQuadrant.importantNotUrgent:
        return '重要不紧急';
      case TaskQuadrant.notImportantUrgent:
        return '不重要但紧急';
      case TaskQuadrant.notImportantNotUrgent:
        return '不重要不紧急';
    }
  }

  int get value {
    switch (this) {
      case TaskQuadrant.importantUrgent:
        return 0;
      case TaskQuadrant.importantNotUrgent:
        return 1;
      case TaskQuadrant.notImportantUrgent:
        return 2;
      case TaskQuadrant.notImportantNotUrgent:
        return 3;
    }
  }

  static TaskQuadrant fromValue(int value) {
    switch (value) {
      case 0:
        return TaskQuadrant.importantUrgent;
      case 1:
        return TaskQuadrant.importantNotUrgent;
      case 2:
        return TaskQuadrant.notImportantUrgent;
      case 3:
      default:
        return TaskQuadrant.notImportantNotUrgent;
    }
  }
}

enum TaskDueMode { day, time }

extension TaskDueModeX on TaskDueMode {
  String get label {
    switch (this) {
      case TaskDueMode.day:
        return '当天截止';
      case TaskDueMode.time:
        return '精确时间';
    }
  }

  String get value {
    switch (this) {
      case TaskDueMode.day:
        return 'day';
      case TaskDueMode.time:
        return 'time';
    }
  }

  static TaskDueMode fromValue(String? value) {
    return value == 'time' ? TaskDueMode.time : TaskDueMode.day;
  }
}

enum TaskRepeatType { none, daily, weekly, weeklyCustom, monthly, yearly }

extension TaskRepeatTypeX on TaskRepeatType {
  String get label {
    switch (this) {
      case TaskRepeatType.none:
        return '不重复';
      case TaskRepeatType.daily:
        return '每天';
      case TaskRepeatType.weekly:
        return '每周';
      case TaskRepeatType.monthly:
        return '每月';
      case TaskRepeatType.weeklyCustom:
        return '每周指定日期';
      case TaskRepeatType.yearly:
        return '每年';
    }
  }

  String get value {
    switch (this) {
      case TaskRepeatType.none:
        return 'none';
      case TaskRepeatType.daily:
        return 'daily';
      case TaskRepeatType.weekly:
        return 'weekly';
      case TaskRepeatType.monthly:
        return 'monthly';
      case TaskRepeatType.weeklyCustom:
        return 'weekly_custom';
      case TaskRepeatType.yearly:
        return 'yearly';
    }
  }

  static TaskRepeatType fromValue(String? value) {
    switch (value) {
      case 'daily':
        return TaskRepeatType.daily;
      case 'weekly':
        return TaskRepeatType.weekly;
      case 'monthly':
        return TaskRepeatType.monthly;
      case 'weekly_custom':
        return TaskRepeatType.weeklyCustom;
      case 'yearly':
        return TaskRepeatType.yearly;
      case 'none':
      default:
        return TaskRepeatType.none;
    }
  }
}

enum TaskType { personal, shared }

extension TaskTypeX on TaskType {
  String get label {
    switch (this) {
      case TaskType.personal:
        return '个人任务';
      case TaskType.shared:
        return '共同任务';
    }
  }

  String get value {
    switch (this) {
      case TaskType.personal:
        return 'personal';
      case TaskType.shared:
        return 'shared';
    }
  }

  static TaskType fromValue(String? value) {
    return value == 'shared' ? TaskType.shared : TaskType.personal;
  }
}

enum TaskCompletionMode { anyOne, allRequired }

extension TaskCompletionModeX on TaskCompletionMode {
  String get label {
    switch (this) {
      case TaskCompletionMode.anyOne:
        return '任意一人完成';
      case TaskCompletionMode.allRequired:
        return '双方都要完成';
    }
  }

  String get value {
    switch (this) {
      case TaskCompletionMode.anyOne:
        return 'any_one';
      case TaskCompletionMode.allRequired:
        return 'all_required';
    }
  }

  static TaskCompletionMode fromValue(String? value) {
    return value == 'all_required'
        ? TaskCompletionMode.allRequired
        : TaskCompletionMode.anyOne;
  }
}

class TaskItem {
  TaskItem({
    this.id,
    required this.title,
    this.note,
    required this.quadrant,
    this.points = 0,
    this.dueDate,
    this.dueMode = TaskDueMode.day,
    this.repeatType = TaskRepeatType.none,
    this.repeatInterval = 1,
    this.repeatWeekdays = const [],
    this.repeatUntil,
    this.taskType = TaskType.personal,
    this.completionMode = TaskCompletionMode.anyOne,
    this.doneByMe = false,
    this.doneByPartner = false,
    this.creator = 'me',
    this.isDone = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final int? id;
  final String title;
  final String? note;
  final TaskQuadrant quadrant;
  final int points;
  final DateTime? dueDate;
  final TaskDueMode dueMode;
  final TaskRepeatType repeatType;
  final int repeatInterval;
  final List<int> repeatWeekdays;
  final DateTime? repeatUntil;
  final TaskType taskType;
  final TaskCompletionMode completionMode;
  final bool doneByMe;
  final bool doneByPartner;
  final String creator;
  final bool isDone;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskItem copyWith({
    int? id,
    String? title,
    String? note,
    TaskQuadrant? quadrant,
    int? points,
    DateTime? dueDate,
    TaskDueMode? dueMode,
    TaskRepeatType? repeatType,
    int? repeatInterval,
    List<int>? repeatWeekdays,
    DateTime? repeatUntil,
    TaskType? taskType,
    TaskCompletionMode? completionMode,
    bool? doneByMe,
    bool? doneByPartner,
    String? creator,
    bool? isDone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      quadrant: quadrant ?? this.quadrant,
      points: points ?? this.points,
      dueDate: dueDate ?? this.dueDate,
      dueMode: dueMode ?? this.dueMode,
      repeatType: repeatType ?? this.repeatType,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
      repeatUntil: repeatUntil ?? this.repeatUntil,
      taskType: taskType ?? this.taskType,
      completionMode: completionMode ?? this.completionMode,
      doneByMe: doneByMe ?? this.doneByMe,
      doneByPartner: doneByPartner ?? this.doneByPartner,
      creator: creator ?? this.creator,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'quadrant': quadrant.value,
      'points': points,
      'due_date': dueDate?.toIso8601String(),
      'due_mode': dueMode.value,
      'repeat_type': repeatType.value,
      'repeat_interval': repeatInterval,
      'repeat_weekdays': repeatWeekdays.join(','),
      'repeat_until': repeatUntil?.toIso8601String(),
      'task_type': taskType.value,
      'completion_mode': completionMode.value,
      'done_by_me': doneByMe ? 1 : 0,
      'done_by_partner': doneByPartner ? 1 : 0,
      'creator': creator,
      'is_done': isDone ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static TaskItem fromMap(Map<String, Object?> map) {
    return TaskItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      note: map['note'] as String?,
      quadrant: TaskQuadrantX.fromValue(map['quadrant'] as int),
      points: (map['points'] as int?) ?? 0,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      dueMode: TaskDueModeX.fromValue(map['due_mode'] as String?),
      repeatType: TaskRepeatTypeX.fromValue(map['repeat_type'] as String?),
      repeatInterval: (map['repeat_interval'] as int?) ?? 1,
      repeatWeekdays: ((map['repeat_weekdays'] as String?) ?? '')
          .split(',')
          .map((s) => int.tryParse(s.trim()))
          .whereType<int>()
          .where((d) => d >= 1 && d <= 7)
          .toList(),
      repeatUntil: map['repeat_until'] != null
          ? DateTime.parse(map['repeat_until'] as String)
          : null,
      taskType: TaskTypeX.fromValue(map['task_type'] as String?),
      completionMode: TaskCompletionModeX.fromValue(
        map['completion_mode'] as String?,
      ),
      doneByMe: ((map['done_by_me'] as int?) ?? 0) == 1,
      doneByPartner: ((map['done_by_partner'] as int?) ?? 0) == 1,
      creator: (map['creator'] as String?) ?? 'me',
      isDone: ((map['is_done'] as int?) ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
