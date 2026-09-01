// =============================================================================
// DatabaseHelper – local persistence layer (SharedPreferences-backed)
// =============================================================================

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/formulation_record.dart';

/// Singleton that manages the app's local storage of [FormulationRecord]s.
///
/// Backed by [SharedPreferences], which maps to native prefs on
/// Android/iOS/desktop and to `localStorage` on web — so, unlike a
/// platform-specific SQLite plugin, it works identically on every platform
/// Flutter can target (including a web build, e.g. a Vercel-hosted
/// prototype) with no extra native setup.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _recordsKey = 'formulation_records';
  static const String _nextIdKey = 'formulation_next_id';

  /// Inserts a new [FormulationRecord] and returns its new row id.
  Future<int> insertRecord(FormulationRecord record) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int id = prefs.getInt(_nextIdKey) ?? 1;

    final List<Map<String, dynamic>> records = _readAll(prefs);
    records.insert(0, {...record.toMap(), 'id': id});

    await _writeAll(prefs, records);
    await prefs.setInt(_nextIdKey, id + 1);
    return id;
  }

  /// Returns all saved records, newest first.
  Future<List<FormulationRecord>> fetchAllRecords() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return _readAll(prefs).map(FormulationRecord.fromMap).toList();
  }

  /// Deletes a single record by [id].
  Future<void> deleteRecord(int id) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> records = _readAll(prefs)
      ..removeWhere((Map<String, dynamic> r) => r['id'] == id);
    await _writeAll(prefs, records);
  }

  /// No-op, kept for API compatibility — SharedPreferences has no explicit
  /// connection to close.
  Future<void> close() async {}

  // ---------------------------------------------------------------------------
  // Internal (de)serialisation helpers
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _readAll(SharedPreferences prefs) {
    final List<String> raw = prefs.getStringList(_recordsKey) ?? <String>[];
    return raw
        .map((String s) => Map<String, dynamic>.from(
              jsonDecode(s) as Map<dynamic, dynamic>,
            ))
        .toList();
  }

  Future<void> _writeAll(
    SharedPreferences prefs,
    List<Map<String, dynamic>> records,
  ) {
    return prefs.setStringList(
      _recordsKey,
      records.map(jsonEncode).toList(),
    );
  }
}
