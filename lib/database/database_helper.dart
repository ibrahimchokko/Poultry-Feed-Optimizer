// =============================================================================
// DatabaseHelper – singleton SQLite access layer
// =============================================================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../models/formulation_record.dart';

/// Singleton that manages the app's SQLite database connection.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  /// Returns the open database, initialising it on first access.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, 'feed_formulation.db');

    return openDatabase(
      fullPath,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE formulations (
            id        INTEGER PRIMARY KEY AUTOINCREMENT,
            type      TEXT    NOT NULL,
            age       TEXT    NOT NULL,
            amount    INTEGER NOT NULL,
            formulation TEXT  NOT NULL
          )
        ''');
      },
    );
  }

  /// Inserts a new [FormulationRecord] and returns its row id.
  Future<int> insertRecord(FormulationRecord record) async {
    final db = await database;
    return db.insert(
      'formulations',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Returns all saved records, newest first.
  Future<List<FormulationRecord>> fetchAllRecords() async {
    final db = await database;
    final rows = await db.query('formulations', orderBy: 'id DESC');
    return rows.map(FormulationRecord.fromMap).toList();
  }

  /// Deletes a single record by [id].
  Future<void> deleteRecord(int id) async {
    final db = await database;
    await db.delete('formulations', where: 'id = ?', whereArgs: [id]);
  }

  /// Closes the database connection and resets the cached reference.
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
