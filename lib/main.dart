// =============================================================================
// Poultry Feed Formulation Calculator
// Student ID: KASU/19/CSC/1069
// Architecture: Single-file Flutter app with Material 3 + SQLite (sqflite)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

// =============================================================================
// SECTION 1 – APP ENTRY POINT
// =============================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FeedFormulatorApp());
}

// =============================================================================
// SECTION 2 – ROOT APPLICATION WIDGET
// =============================================================================

class FeedFormulatorApp extends StatelessWidget {
  const FeedFormulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feed Formulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0), // deep blue seed
          brightness: Brightness.light,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        cardTheme: CardThemeData(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const FormulatorHomePage(),
    );
  }
}

// =============================================================================
// SECTION 3 – CONSTANTS & FORMULATION DATA MATRIX
// =============================================================================

/// App bar title shown at all times.
const String kAppTitle = 'Feed Formulator (KASU/19/CSC/1069)';

/// Base daily feed rate per bird (kg) for standard poultry types.
const double kStandardFeedRate = 0.15;

/// Base daily feed rate per bird (kg) for turkeys.
const double kTurkeyFeedRate = 0.25;

/// All supported poultry types (display labels map to internal keys).
const List<String> kPoultryTypes = ['broilers', 'layers', 'noilers', 'turkey'];

/// Scientific feed proportion matrices.
/// Proportions are normalised to 1.0 (i.e., 100 % of feed weight mix).
/// Each inner map represents one age-group formulation for that bird type.
const Map<String, Map<String, Map<String, double>>> kFormulations = {
  'broilers': {
    '1-4': {
      'Maize (8.5% CP)': 0.54,
      'Soybean Meal (44% CP)': 0.35,
      'Fish Meal (65% CP)': 0.05,
      'Bone Meal': 0.03,
      'Limestone': 0.02,
      'Lysine + Methionine': 0.005,
      'Vitamin/Mineral Premix': 0.005,
    },
    '5-8': {
      'Maize (8.5% CP)': 0.61,
      'Soybean Meal (44% CP)': 0.29,
      'Fish Meal (65% CP)': 0.03,
      'Bone Meal': 0.03,
      'Limestone': 0.03,
      'Lysine + Methionine': 0.004,
      'Vitamin/Mineral Premix': 0.006,
    },
  },
  'layers': {
    '1-4': {
      'Maize (8.5% CP)': 0.58,
      'Soybean Meal (44% CP)': 0.25,
      'Wheat Offal': 0.09,
      'Bone Meal': 0.03,
      'Limestone': 0.04,
      'Vitamin/Mineral Premix': 0.01,
    },
    '18+': {
      'Maize (8.5% CP)': 0.50,
      'Soybean Meal (44% CP)': 0.22,
      'Wheat Offal': 0.12,
      'Bone Meal': 0.04,
      'Limestone': 0.11, // High Ca for eggshell strength
      'Vitamin/Mineral Premix': 0.01,
    },
  },
  'noilers': {
    '1-4': {
      'Maize (8.5% CP)': 0.55,
      'Soybean Meal (44% CP)': 0.32,
      'Wheat Offal': 0.05,
      'Bone Meal': 0.03,
      'Limestone': 0.04,
      'Vitamin/Mineral Premix': 0.01,
    },
    '5-8': {
      'Maize (8.5% CP)': 0.60,
      'Soybean Meal (44% CP)': 0.26,
      'Wheat Offal': 0.06,
      'Bone Meal': 0.03,
      'Limestone': 0.04,
      'Vitamin/Mineral Premix': 0.01,
    },
  },
  'turkey': {
    '1-4': {
      'Maize (8.5% CP)': 0.44,
      'Soybean Meal (44% CP)': 0.43,
      'Fish Meal (65% CP)': 0.07,
      'Bone Meal': 0.03,
      'Limestone': 0.02,
      'Lysine + Methionine': 0.005,
      'Vitamin/Mineral Premix': 0.005,
    },
    '5-8': {
      'Maize (8.5% CP)': 0.50,
      'Soybean Meal (44% CP)': 0.38,
      'Fish Meal (65% CP)': 0.05,
      'Bone Meal': 0.03,
      'Limestone': 0.03,
      'Lysine + Methionine': 0.005,
      'Vitamin/Mineral Premix': 0.006,
    },
    '9-16': {
      'Maize (8.5% CP)': 0.58,
      'Soybean Meal (44% CP)': 0.30,
      'Fish Meal (65% CP)': 0.04,
      'Bone Meal': 0.03,
      'Limestone': 0.04,
      'Lysine + Methionine': 0.004,
      'Vitamin/Mineral Premix': 0.006,
    },
  },
};

// =============================================================================
// SECTION 4 – DATA MODEL
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

// =============================================================================
// SECTION 5 – DATABASE HELPER (SINGLETON)
// =============================================================================

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

// =============================================================================
// SECTION 6 – HOME PAGE STATEFUL WIDGET
// =============================================================================

class FormulatorHomePage extends StatefulWidget {
  const FormulatorHomePage({super.key});

  @override
  State<FormulatorHomePage> createState() => _FormulatorHomePageState();
}

class _FormulatorHomePageState extends State<FormulatorHomePage> {
  // ── Controllers ────────────────────────────────────────────────────────────
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _flockController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ── State fields ───────────────────────────────────────────────────────────
  String _selectedType = kPoultryTypes.first;
  bool _isCalculating = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _ageController.dispose();
    _flockController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // BUSINESS LOGIC
  // ==========================================================================

  /// Resolves the correct age-group key for a given [type] and [ageWeeks].
  String _resolveAgeGroup(String type, int ageWeeks) {
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

  /// Returns the base daily feed rate (kg/bird) for [type].
  double _feedRate(String type) =>
      type == 'turkey' ? kTurkeyFeedRate : kStandardFeedRate;

  /// Validates inputs, runs the formulation calculation, persists to SQLite,
  /// and returns the result string. Returns null on validation failure.
  Future<String?> _calculate() async {
    if (!(_formKey.currentState?.validate() ?? false)) return null;

    setState(() => _isCalculating = true);

    try {
      final int ageWeeks = int.parse(_ageController.text.trim());
      final int flockSize = int.parse(_flockController.text.trim());

      final String ageGroup = _resolveAgeGroup(_selectedType, ageWeeks);
      final double totalFeed = flockSize * _feedRate(_selectedType);
      final Map<String, double> proportions =
          kFormulations[_selectedType]![ageGroup]!;

      // Build a human-readable recipe string.
      final StringBuffer sb = StringBuffer();
      sb.writeln('═══════════════════════════════════');
      sb.writeln('  FEED FORMULATION RESULT');
      sb.writeln('═══════════════════════════════════');
      sb.writeln('  Bird Type  : ${_selectedType.toUpperCase()}');
      sb.writeln('  Age Group  : $ageGroup weeks');
      sb.writeln('  Flock Size : $flockSize birds');
      sb.writeln('  Total Feed : ${totalFeed.toStringAsFixed(3)} kg/day');
      sb.writeln('───────────────────────────────────');
      sb.writeln('  INGREDIENT BREAKDOWN (kg/day)');
      sb.writeln('───────────────────────────────────');

      for (final entry in proportions.entries) {
        final double kg = entry.value * totalFeed;
        sb.writeln('  ${entry.key}');
        sb.writeln('    → ${kg.toStringAsFixed(3)} kg'
            '  (${(entry.value * 100).toStringAsFixed(1)}%)');
      }

      sb.writeln('═══════════════════════════════════');

      final String result = sb.toString();

      // Persist to SQLite.
      await DatabaseHelper.instance.insertRecord(
        FormulationRecord(
          type: _selectedType,
          age: ageGroup,
          amount: flockSize,
          formulation: result,
        ),
      );

      return result;
    } finally {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  // ── Snackbar helpers ───────────────────────────────────────────────────────

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  /// Called when the Calculate button is pressed.
  Future<void> _onCalculatePressed() async {
    FocusScope.of(context).unfocus();

    final String? result = await _calculate();
    if (result == null) return; // validation failed

    _showSuccess('Formulation calculated and saved!');
    if (mounted) _showResultDialog(result);
  }

  /// Opens the draggable history bottom sheet.
  void _onHistoryPressed() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _HistoryBottomSheet(),
    );
  }

  /// Shows the calculation result inside a scrollable AlertDialog.
  void _showResultDialog(String result) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.grass, color: Theme.of(ctx).colorScheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Formulation Result',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                result,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(ctx).pop(),
              icon: const Icon(Icons.close),
              label: const Text('Close'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // BUILD – SCAFFOLD, APP BAR, INPUT CARD
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 4,
        centerTitle: false,
        title: const Text(
          kAppTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 0.4,
          ),
        ),
        actions: [
          Tooltip(
            message: 'Calculation History',
            child: IconButton(
              icon: const Icon(Icons.history),
              onPressed: _onHistoryPressed,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Hero banner ──────────────────────────────────────────
                _buildHeroBanner(cs),
                const SizedBox(height: 24),

                // ── Parameter entry card ─────────────────────────────────
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Feed Parameters',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                        ),
                        const SizedBox(height: 20),

                        // Poultry type dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Poultry Type',
                            prefixIcon: Icon(Icons.pets),
                          ),
                          items: kPoultryTypes
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t[0].toUpperCase() + t.substring(1),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedType = value);
                            }
                          },
                          validator: (value) =>
                              value == null ? 'Select a poultry type' : null,
                        ),
                        const SizedBox(height: 16),

                        // Age in weeks field
                        TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Age in Weeks',
                            hintText: 'e.g. 3',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the bird age in weeks';
                            }
                            final int? v = int.tryParse(value.trim());
                            if (v == null || v <= 0) {
                              return 'Age must be a positive whole number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Flock size field
                        TextFormField(
                          controller: _flockController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Flock Size (number of birds)',
                            hintText: 'e.g. 500',
                            prefixIcon: Icon(Icons.groups_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter the flock size';
                            }
                            final int? v = int.tryParse(value.trim());
                            if (v == null || v <= 0) {
                              return 'Flock size must be a positive whole number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),

                        // Calculate button
                        SizedBox(
                          height: 54,
                          child: ElevatedButton.icon(
                            onPressed:
                                _isCalculating ? null : _onCalculatePressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                            ),
                            icon: _isCalculating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.calculate, size: 22),
                            label: Text(
                              _isCalculating
                                  ? 'Calculating…'
                                  : 'Calculate Formulation',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Info footer ──────────────────────────────────────────
                _buildInfoFooter(cs),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Private UI helpers ─────────────────────────────────────────────────────

  Widget _buildHeroBanner(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withAlpha(76),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.egg_alt_outlined, color: Colors.white, size: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Poultry Feed Calculator',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Goal-programming optimisation\nfor precise feed formulation',
                  style: TextStyle(
                    color: Colors.white.withAlpha(220),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoFooter(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withAlpha(120),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: cs.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Feed rates: Broilers / Layers / Noilers → 0.15 kg/bird/day. '
              'Turkeys → 0.25 kg/bird/day. '
              'All results are stored locally for future reference.',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSecondaryContainer,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
} // end _FormulatorHomePageState

// =============================================================================
// SECTION 7 – HISTORY BOTTOM SHEET WIDGET
// =============================================================================

class _HistoryBottomSheet extends StatefulWidget {
  const _HistoryBottomSheet();

  @override
  State<_HistoryBottomSheet> createState() => _HistoryBottomSheetState();
}

class _HistoryBottomSheetState extends State<_HistoryBottomSheet> {
  late Future<List<FormulationRecord>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    _recordsFuture = DatabaseHelper.instance.fetchAllRecords();
  }

  Future<void> _deleteRecord(int id) async {
    await DatabaseHelper.instance.deleteRecord(id);
    if (mounted) setState(_loadRecords);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (BuildContext ctx, ScrollController scrollController) {
        return Column(
          children: [
            // ── Drag handle + header ────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        Icon(Icons.history, color: cs.primary),
                        const SizedBox(width: 10),
                        Text(
                          'Calculation History',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: cs.outlineVariant),
                ],
              ),
            ),

            // ── Records list ────────────────────────────────────────────
            Expanded(
              child: FutureBuilder<List<FormulationRecord>>(
                future: _recordsFuture,
                builder: (
                  BuildContext futureCtx,
                  AsyncSnapshot<List<FormulationRecord>> snapshot,
                ) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Failed to load history:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: cs.error),
                        ),
                      ),
                    );
                  }

                  final List<FormulationRecord> records =
                      snapshot.data ?? <FormulationRecord>[];

                  if (records.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: cs.outlineVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No calculations saved yet.',
                            style: TextStyle(color: cs.outline),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (BuildContext listCtx, int index) {
                      final FormulationRecord rec = records[index];
                      return _HistoryCard(
                        record: rec,
                        onDelete: () => _deleteRecord(rec.id!),
                        onTap: () => _showDetailDialog(context, rec),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Shows the full stored formulation text in a scrollable dialog.
  void _showDetailDialog(BuildContext context, FormulationRecord rec) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (BuildContext dCtx) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.article_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${rec.type[0].toUpperCase()}${rec.type.substring(1)} '
                  '– ${rec.age} wks',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                rec.formulation,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => Navigator.of(dCtx).pop(),
              icon: const Icon(Icons.close),
              label: const Text('Close'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }
}

// =============================================================================
// SECTION 8 – HISTORY CARD WIDGET
// =============================================================================

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.record,
    required this.onDelete,
    required this.onTap,
  });

  final FormulationRecord record;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String typeLabel =
        record.type[0].toUpperCase() + record.type.substring(1);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading icon badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.egg_alt_outlined,
                  color: cs.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Text details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$typeLabel  ·  ${record.age} weeks',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${record.amount} birds',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap to view full recipe',
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              // Delete button
              IconButton(
                icon: Icon(
                  Icons.delete_sweep,
                  color: cs.error,
                ),
                tooltip: 'Delete record',
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
