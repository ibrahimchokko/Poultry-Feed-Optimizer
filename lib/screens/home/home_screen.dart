// =============================================================================
// HomeScreen – main input form and orchestration for the home page
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_constants.dart';
import '../../services/formulation_service.dart';
import '../histoy/history_bottom_sheet.dart';

/// The primary screen of the app. Hosts the parameter entry form and triggers
/// formulation calculations via [FormulationService].
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

  final FormulationService _service = FormulationService();

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _ageController.dispose();
    _flockController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // HANDLERS
  // ==========================================================================

  /// Validates inputs, delegates to [FormulationService.calculate], and shows
  /// the result dialog. Returns null on validation failure.
  Future<String?> _calculate() async {
    if (!(_formKey.currentState?.validate() ?? false)) return null;

    setState(() => _isCalculating = true);

    try {
      return await _service.calculate(
        type: _selectedType,
        ageWeeks: int.parse(_ageController.text.trim()),
        flockSize: int.parse(_flockController.text.trim()),
      );
    } finally {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  Future<void> _onCalculatePressed() async {
    FocusScope.of(context).unfocus();

    final String? result = await _calculate();
    if (result == null) return; // validation failed

    _showSuccess('Formulation calculated and saved!');
    if (mounted) _showResultDialog(result);
  }

  void _onHistoryPressed() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const HistoryBottomSheet(),
    );
  }

  // ==========================================================================
  // DIALOGS & SNACKBARS
  // ==========================================================================

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

  // ==========================================================================
  // BUILD
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
                _buildHeroBanner(cs),
                const SizedBox(height: 24),
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
                            prefixIcon:
                                Icon(Icons.calendar_today_outlined),
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
}
