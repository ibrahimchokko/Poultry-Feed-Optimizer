// =============================================================================
// FormulationRepository – data access layer over DatabaseHelper
// =============================================================================

import '../database/database_helper.dart';
import '../models/formulation_record.dart';

/// Provides a clean API for persisting and retrieving [FormulationRecord]s.
/// All raw SQLite calls are delegated to [DatabaseHelper].
class FormulationRepository {
  FormulationRepository({DatabaseHelper? db})
      : _db = db ?? DatabaseHelper.instance;

  final DatabaseHelper _db;

  /// Saves [record] to the database and returns the new row id.
  Future<int> save(FormulationRecord record) => _db.insertRecord(record);

  /// Returns every saved record, newest first.
  Future<List<FormulationRecord>> getAll() => _db.fetchAllRecords();

  /// Permanently removes the record with [id].
  Future<void> delete(int id) => _db.deleteRecord(id);
}
