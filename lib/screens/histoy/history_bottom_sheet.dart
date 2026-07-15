// =============================================================================
// HistoryBottomSheet – draggable sheet listing all saved formulation records
// =============================================================================

import 'package:flutter/material.dart';

import '../../models/formulation_record.dart';
import '../../repositories/formulation_repository.dart';
import '../../widgets/history_card.dart';

/// A draggable scrollable bottom sheet that loads and displays every saved
/// [FormulationRecord] with tap-to-view and delete support.
class HistoryBottomSheet extends StatefulWidget {
  const HistoryBottomSheet({super.key});

  @override
  State<HistoryBottomSheet> createState() => _HistoryBottomSheetState();
}

class _HistoryBottomSheetState extends State<HistoryBottomSheet> {
  final FormulationRepository _repo = FormulationRepository();
  late Future<List<FormulationRecord>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    _recordsFuture = _repo.getAll();
  }

  Future<void> _deleteRecord(int id) async {
    await _repo.delete(id);
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
                      return HistoryCard(
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
