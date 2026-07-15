// =============================================================================
// FormulationRecord – data model for a saved Poultry-Feed-Optimizer record
// =============================================================================

/// Represents one saved formulation record from the SQLite database.
class FormulationRecord {
  final int? id;
  final String type;
  final String age;
  final int amount;
  final String formulation;

  const FormulationRecord({
    this.id,
    required this.type,
    required this.age,
    required this.amount,
    required this.formulation,
  });

  /// Converts a SQLite row map into a [FormulationRecord].
  factory FormulationRecord.fromMap(Map<String, dynamic> map) {
    return FormulationRecord(
      id: map['id'] as int?,
      type: map['type'] as String,
      age: map['age'] as String,
      amount: map['amount'] as int,
      formulation: map['formulation'] as String,
    );
  }

  /// Converts this record into a map suitable for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'age': age,
      'amount': amount,
      'formulation': formulation,
    };
  }
}
