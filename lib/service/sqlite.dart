import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../model/script.dart';

const databaseName = 'narro.db';
const databaseVersion = 1;
const tableScripts = 'scripts';
const sqlCreateScripts = 'CREATE TABLE $tableScripts ('
    'id TEXT UNIQUE,'
    'title TEXT NOT NULL,'
    'totalLines INTEGER,'
    'extras TEXT NOT NULL)';
const sqlCreateTables = [sqlCreateScripts];

class SqliteService {
  SqliteService._internal();
  static final SqliteService _instance = SqliteService._internal();

  factory SqliteService() {
    return _instance;
  }

  Database? _db;

  Future open() async {
    _db = await openDatabase(
      databaseName,
      version: databaseVersion,
      onCreate: (db, version) async {
        debugPrint('create table');
        for (final sql in sqlCreateTables) {
          await db.execute((sql));
        }
      },
      onUpgrade: (db, oldVersion, newVersion) {
        debugPrint('upgrade table from $oldVersion to $newVersion');
      },
    );
  }

  Future close() async {
    await _db?.close();
  }

  Future<Database> getDatabase() async {
    if (_db == null) {
      await open();
    }
    return _db!;
  }

  //
  // Scripts
  //
  Future<List<Script>> getScripts({Map<String, Object?>? query}) async {
    final db = await getDatabase();
    final records = await db.query(
      tableScripts,
      distinct: query?['distinct'] as bool?,
      columns: query?['columns'] as List<String>?,
      where: query?['where'] as String?,
      whereArgs: query?['whereArgs'] as List<Object>?,
      groupBy: query?['groupBy'] as String?,
      having: query?['having'] as String?,
      orderBy: query?['orderBy'] as String?,
      limit: query?['limit'] as int?,
      offset: query?['offset'] as int?,
    );
    return records.map<Script>((e) => Script.fromSqlite(e)).toList();
  }

  Future<Script?> getScriptById(String id) async {
    final db = await getDatabase();
    final records = await db.query(
      tableScripts,
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('getScriptById.records:$records');
    if (records.isNotEmpty) {
      return Script.fromSqlite(records.first);
    }
    return null;
  }

  Future<int> addScript(Script script) async {
    final db = await getDatabase();
    debugPrint('addScript.script:$script');
    final result = await db.insert(
      tableScripts,
      script.toSqlite(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return result;
  }

  Future<int> updateScript(Script script) async {
    final db = await getDatabase();
    debugPrint('updateScript.script:$script');
    final result = await db.update(
      tableScripts,
      script.toSqlite(),
      where: 'id = ?',
      whereArgs: [script.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return result;
  }

  Future<int> deleteScript(Script script) async {
    final db = await getDatabase();
    final result = await db.delete(
      tableScripts,
      where: 'id = ?',
      whereArgs: [script.id],
    );
    return result;
  }
}
