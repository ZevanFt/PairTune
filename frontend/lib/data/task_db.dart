import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/task_item.dart';

class TaskDb {
  TaskDb._();

  static final TaskDb instance = TaskDb._();
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'priority_first.db');
    _db = await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            note TEXT,
            quadrant INTEGER NOT NULL,
            points INTEGER NOT NULL DEFAULT 0,
            due_date TEXT,
            due_mode TEXT NOT NULL DEFAULT 'day',
            repeat_type TEXT NOT NULL DEFAULT 'none',
            repeat_interval INTEGER NOT NULL DEFAULT 1,
            repeat_weekdays TEXT,
            repeat_until TEXT,
            task_type TEXT NOT NULL DEFAULT 'personal',
            completion_mode TEXT NOT NULL DEFAULT 'any_one',
            done_by_me INTEGER NOT NULL DEFAULT 0,
            done_by_partner INTEGER NOT NULL DEFAULT 0,
            creator TEXT NOT NULL DEFAULT 'me',
            is_done INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE tasks ADD COLUMN repeat_type TEXT NOT NULL DEFAULT 'none'",
          );
          await db.execute(
            'ALTER TABLE tasks ADD COLUMN repeat_interval INTEGER NOT NULL DEFAULT 1',
          );
          await db.execute('ALTER TABLE tasks ADD COLUMN repeat_until TEXT');
        }
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE tasks ADD COLUMN due_mode TEXT NOT NULL DEFAULT 'day'",
          );
          await db.execute('ALTER TABLE tasks ADD COLUMN repeat_weekdays TEXT');
        }
        if (oldVersion < 4) {
          await db.execute(
            "ALTER TABLE tasks ADD COLUMN task_type TEXT NOT NULL DEFAULT 'personal'",
          );
          await db.execute(
            "ALTER TABLE tasks ADD COLUMN completion_mode TEXT NOT NULL DEFAULT 'any_one'",
          );
          await db.execute(
            'ALTER TABLE tasks ADD COLUMN done_by_me INTEGER NOT NULL DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE tasks ADD COLUMN done_by_partner INTEGER NOT NULL DEFAULT 0',
          );
          await db.execute(
            "ALTER TABLE tasks ADD COLUMN creator TEXT NOT NULL DEFAULT 'me'",
          );
        }
      },
    );
    return _db!;
  }

  Future<List<TaskItem>> listTasks() async {
    final db = await database;
    final rows = await db.query(
      'tasks',
      orderBy: 'is_done ASC, updated_at DESC',
    );
    return rows.map(TaskItem.fromMap).toList();
  }

  Future<int> insertTask(TaskItem task) async {
    final db = await database;
    return db.insert('tasks', task.toMap());
  }

  Future<void> updateTask(TaskItem task) async {
    final db = await database;
    await db.update(
      'tasks',
      task.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('tasks');
  }
}
