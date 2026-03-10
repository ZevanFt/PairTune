import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AuthSessionStore {
  static const _table = 'auth_session_kv';
  static const _keyToken = 'auth_token';

  Future<Database> _openDb() async {
    final dbPath = await getDatabasesPath();
    final file = p.join(dbPath, 'auth_session.db');
    return openDatabase(
      file,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE IF NOT EXISTS $_table(key TEXT PRIMARY KEY, value TEXT NOT NULL)',
        );
      },
    );
  }

  Future<String?> getToken() async {
    final db = await _openDb();
    final rows = await db.query(
      _table,
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [_keyToken],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> saveToken(String token) async {
    final db = await _openDb();
    await db.insert(
      _table,
      {'key': _keyToken, 'value': token},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearToken() async {
    final db = await _openDb();
    await db.delete(
      _table,
      where: 'key = ?',
      whereArgs: [_keyToken],
    );
  }
}
