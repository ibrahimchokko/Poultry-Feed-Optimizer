// =============================================================================
// FormulationService – age-group resolution, feed-rate lookup, and calculation
// =============================================================================

import '../constants/app_constants.dart';
import '../models/formulation_record.dart';
import '../repositories/formulation_repository.dart';

/// Pure business-logic service for poultry feed optimisation.
///
/// Depends on [FormulationRepository] to persist results after calculation.
class FormulationService {
  FormulationService({FormulationRepository? repository})
      : _repo = repository ?? FormulationRepository();

  final FormulationRepository _repo;

  // ---------------------------------------------------------------------------
  // Age-group resolution
  // ---------------------------------------------------------------------------

  /// Returns the age-group key (e.g. `'1-4'`, `'5-8'`, `'18+'`) for the given
  /// [type] and [ageWeeks].
  String resolveAgeGroup(String type, int ageWeeks) {
    switch (type) {
      case 'broilers':
        return ageWeeks <= 4 ? '1-4' : '5-8';
      case 'layers':
        return ageWeeks < 18 ? '1-4' : '18+';
      case 'noilers':
        return ageWeeks <= 4 ? '1-4' : '5-8';
      case 'turkey':
        if (ageWeeks <= 4) return '1-4';
        if (ageWeeks <= 8) return '5-8';
        return '9-16';
      default:
        return '1-4';
    }
  }

  // ---------------------------------------------------------------------------
  // Feed-rate lookup
  // ---------------------------------------------------------------------------

  /// Returns the base daily feed rate (kg/bird) for [type].
  double feedRate(String type) =>
      type == 'turkey' ? kTurkeyFeedRate : kStandardFeedRate;

  // ---------------------------------------------------------------------------
  // Calculation + persistence
  // ---------------------------------------------------------------------------

  /// Runs the formulation calculation for the given parameters, persists the
  /// result via [FormulationRepository], and returns the formatted recipe
  /// string.
  Future<String> calculate({
    required String type,
    required int ageWeeks,
    required int flockSize,
  }) async {
    final String ageGroup = resolveAgeGroup(type, ageWeeks);
    final double totalFeed = flockSize * feedRate(type);
    final Map<String, double> proportions = kFormulations[type]![ageGroup]!;

    // Build a human-readable recipe string.
    final StringBuffer sb = StringBuffer();
    sb.writeln('═══════════════════════════════════');
    sb.writeln('  POULTRY-FEED-OPTIMIZER RESULT');
    sb.writeln('═══════════════════════════════════');
    sb.writeln('  Bird Type  : ${type.toUpperCase()}');
    sb.writeln('  Age Group  : $ageGroup weeks');
    sb.writeln('  Flock Size : $flockSize birds');
    sb.writeln('  Total Feed : ${totalFeed.toStringAsFixed(3)} kg/day');
    sb.writeln('───────────────────────────────────');
    sb.writeln('  INGREDIENT BREAKDOWN (kg/day)');
    sb.writeln('───────────────────────────────────');

    for (final MapEntry<String, double> entry in proportions.entries) {
      final double kg = entry.value * totalFeed;
      sb.writeln('  ${entry.key}');
      sb.writeln('    → ${kg.toStringAsFixed(3)} kg'
          '  (${(entry.value * 100).toStringAsFixed(1)}%)');
    }

    sb.writeln('═══════════════════════════════════');

    final String result = sb.toString();

    // Persist to SQLite via the repository.
    await _repo.save(
      FormulationRecord(
        type: type,
        age: ageGroup,
        amount: flockSize,
        formulation: result,
      ),
    );

    return result;
  }
}
