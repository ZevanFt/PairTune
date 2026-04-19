import 'dart:convert';

import '../models/task_item.dart';
import 'api_base.dart';
import 'api_error.dart';

class TaskApiService extends ApiBase {
  TaskApiService({super.client});

  @override
  String get tag => 'Task';

  static const String _metaPrefix = '<!--PFMETA:';
  static const String _metaSuffix = '-->';

  Future<List<TaskItem>> listTasks(String owner) async {
    final data = await get('/tasks?owner=$owner');
    final list = ApiBase.resultList(data);
    return list.map(_fromApi).toList();
  }

  Future<TaskItem> createTask(TaskItem item, String owner) async {
    final encodedNote = _encodeNoteWithMeta(item.note, item);
    final data = await post('/tasks', {
      'owner': owner,
      'title': item.title,
      'note': encodedNote,
      'quadrant': item.quadrant.value,
      'points': item.points,
      'due_date': item.dueDate?.toIso8601String(),
      'due_mode': item.dueMode.value,
      'repeat_type': item.repeatType.value,
      'repeat_interval': item.repeatInterval,
      'repeat_weekdays': item.repeatWeekdays,
      'repeat_until': item.repeatUntil?.toIso8601String(),
      'task_type': item.taskType.value,
      'completion_mode': item.completionMode.value,
      'done_by_me': item.doneByMe ? 1 : 0,
      'done_by_partner': item.doneByPartner ? 1 : 0,
      'creator': item.creator,
    });
    return _fromApi(ApiBase.result(data));
  }

  Future<TaskItem> updateTask(TaskItem item, String owner) async {
    final id = item.id;
    if (id == null) {
      throw ApiHttpError(statusCode: 400, statusText: '任务ID缺失');
    }
    final encodedNote = _encodeNoteWithMeta(item.note, item);
    final data = await patch('/tasks/$id?owner=$owner', {
      'title': item.title,
      'note': encodedNote,
      'quadrant': item.quadrant.value,
      'points': item.points,
      'due_date': item.dueDate?.toIso8601String(),
      'due_mode': item.dueMode.value,
      'repeat_type': item.repeatType.value,
      'repeat_interval': item.repeatInterval,
      'repeat_weekdays': item.repeatWeekdays,
      'repeat_until': item.repeatUntil?.toIso8601String(),
      'task_type': item.taskType.value,
      'completion_mode': item.completionMode.value,
      'done_by_me': item.doneByMe ? 1 : 0,
      'done_by_partner': item.doneByPartner ? 1 : 0,
      'is_done': item.isDone ? 1 : 0,
    });
    return _fromApi(ApiBase.result(data));
  }

  Future<void> deleteTask(int id, String owner) async {
    await delete('/tasks/$id?owner=$owner');
  }

  TaskItem _fromApi(Map<String, dynamic> raw) {
    final noteRaw = raw['note'] as String?;
    final meta = _extractMeta(noteRaw);
    final repeatWeekdaysRaw = raw['repeat_weekdays'];
    final repeatWeekdays = repeatWeekdaysRaw is List
        ? repeatWeekdaysRaw.whereType<num>().map((n) => n.toInt()).where((d) => d >= 1 && d <= 7).toList()
        : (repeatWeekdaysRaw is String
            ? repeatWeekdaysRaw.split(',').map((s) => int.tryParse(s.trim())).whereType<int>().where((d) => d >= 1 && d <= 7).toList()
            : <int>[]);

    final taskType = TaskTypeX.fromValue((raw['task_type'] as String?) ?? meta['task_type'] as String?);
    final completionMode = TaskCompletionModeX.fromValue((raw['completion_mode'] as String?) ?? meta['completion_mode'] as String?);
    final doneByMe = _toBool(raw['done_by_me']) || _toBool(meta['done_by_me']);
    final doneByPartner = _toBool(raw['done_by_partner']) || _toBool(meta['done_by_partner']);
    final creator = (raw['creator'] as String?) ?? (meta['creator'] as String?) ?? 'me';

    return TaskItem(
      id: raw['id'] as int?,
      title: raw['title'] as String,
      note: _stripMeta(noteRaw),
      quadrant: TaskQuadrantX.fromValue((raw['quadrant'] as num).toInt()),
      points: ((raw['points'] as num?) ?? 0).toInt(),
      dueDate: raw['due_date'] != null ? DateTime.parse(raw['due_date'] as String) : null,
      dueMode: TaskDueModeX.fromValue(raw['due_mode'] as String?),
      repeatType: TaskRepeatTypeX.fromValue(raw['repeat_type'] as String?),
      repeatInterval: ((raw['repeat_interval'] as num?) ?? 1).toInt(),
      repeatWeekdays: repeatWeekdays,
      repeatUntil: raw['repeat_until'] != null ? DateTime.parse(raw['repeat_until'] as String) : null,
      taskType: taskType,
      completionMode: completionMode,
      doneByMe: doneByMe,
      doneByPartner: doneByPartner,
      creator: creator,
      isDone: (((raw['is_done'] as num?) ?? 0).toInt()) == 1,
      createdAt: DateTime.parse(raw['created_at'] as String),
      updatedAt: DateTime.parse(raw['updated_at'] as String),
    );
  }

  bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value.toInt() == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  String? _encodeNoteWithMeta(String? note, TaskItem item) {
    final cleanNote = _stripMeta(note);
    final meta = {
      'task_type': item.taskType.value,
      'completion_mode': item.completionMode.value,
      'done_by_me': item.doneByMe ? 1 : 0,
      'done_by_partner': item.doneByPartner ? 1 : 0,
      'creator': item.creator,
    };
    return '${cleanNote ?? ''}\n\n$_metaPrefix${jsonEncode(meta)}$_metaSuffix';
  }

  String? _stripMeta(String? note) {
    if (note == null) return null;
    final start = note.indexOf(_metaPrefix);
    if (start < 0) return note;
    return note.substring(0, start).trim().isEmpty ? null : note.substring(0, start).trim();
  }

  Map<String, dynamic> _extractMeta(String? note) {
    if (note == null) return const {};
    final start = note.indexOf(_metaPrefix);
    if (start < 0) return const {};
    final contentStart = start + _metaPrefix.length;
    final end = note.indexOf(_metaSuffix, contentStart);
    if (end < 0) return const {};
    final raw = note.substring(contentStart, end).trim();
    if (raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return const {};
    } catch (_) {
      return const {};
    }
  }
}
