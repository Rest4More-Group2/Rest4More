import 'package:flutter/material.dart';
import 'package:rest4more/data/database/converters.dart' show RoutineStepData;
import 'package:rest4more/data/moments/moment_schedule.dart';

import 'today_screen.dart' show RestPalette, RestType;

/// Lijst met stappen van een routine: toevoegen, aanpassen, verplaatsen en
/// weghalen. De pagina houdt de stappen zelf bij; deze widget meldt elke
/// wijziging via [onChanged].
class RoutineStepsEditor extends StatefulWidget {
  const RoutineStepsEditor({
    super.key,
    required this.steps,
    required this.library,
    required this.onChanged,
    this.emptyText = 'No steps yet. Add the first one.',
  });

  final List<RoutineStepData> steps;
  final List<RoutineStepData> library;
  final ValueChanged<List<RoutineStepData>> onChanged;
  final String emptyText;

  @override
  State<RoutineStepsEditor> createState() => _RoutineStepsEditorState();
}

class _RoutineStepsEditorState extends State<RoutineStepsEditor> {
  // Eigen sleutels per rij, zodat verplaatsen de juiste rij meeneemt.
  late List<int> _ids = List.generate(widget.steps.length, (i) => i);
  late int _nextId = widget.steps.length;

  List<RoutineStepData> get _steps => widget.steps;

  void _emit(List<RoutineStepData> steps) => widget.onChanged(steps);

  void _add(RoutineStepData step) {
    _ids = [..._ids, _nextId++];
    _emit([..._steps, step]);
  }

  void _remove(int index) {
    _ids = [..._ids]..removeAt(index);
    _emit([..._steps]..removeAt(index));
  }

  void _reorder(int from, int to) {
    final ids = [..._ids];
    final steps = [..._steps];
    ids.insert(to, ids.removeAt(from));
    steps.insert(to, steps.removeAt(from));
    _ids = ids;
    _emit(steps);
  }

  void _replace(int index, RoutineStepData step) {
    final steps = [..._steps];
    steps[index] = step;
    _emit(steps);
  }

  Future<void> _edit(int index) async {
    final result = await showDialog<RoutineStepData>(
      context: context,
      builder: (_) => _StepDialog(initial: _steps[index], title: 'Edit step'),
    );
    if (result != null) _replace(index, result);
  }

  Future<void> _addCustom() async {
    final result = await showDialog<RoutineStepData>(
      context: context,
      builder: (_) => const _StepDialog(
        initial: RoutineStepData(title: '', durationMin: 10),
        title: 'New step',
      ),
    );
    if (result != null) _add(result);
  }

  Future<void> _addFromLibrary() async {
    final picked = await showModalBottomSheet<RoutineStepData?>(
      context: context,
      backgroundColor: RestPalette.background,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            children: [
              Text('Add a step', style: RestType.serif(28)),
              const SizedBox(height: 8),
              for (final item in widget.library)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.title, style: RestType.sans(16)),
                  trailing: Text(
                    formatDuration(stepMinutes(item)),
                    style: RestType.sans(14, color: RestPalette.accent),
                  ),
                  onTap: () => Navigator.pop(context, item),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.add, color: RestPalette.primary),
                title: Text(
                  'Your own step',
                  style: RestType.sans(
                    16,
                    color: RestPalette.primary,
                    weight: FontWeight.w600,
                  ),
                ),
                onTap: () => Navigator.pop(
                  context,
                  const RoutineStepData(title: ''),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null) return;
    if (picked.title.isEmpty) {
      await _addCustom();
    } else {
      _add(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Houd de sleutels gelijk aan het aantal stappen, ook als de pagina de
    // lijst van buiten vervangt.
    if (_ids.length != _steps.length) {
      _ids = List.generate(_steps.length, (i) => _nextId + i);
      _nextId += _steps.length;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_steps.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(widget.emptyText, style: RestType.sans(15)),
          )
        else
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: _reorder,
            children: [
              for (var i = 0; i < _steps.length; i++)
                _StepRow(
                  key: ValueKey(_ids[i]),
                  index: i,
                  step: _steps[i],
                  onTap: () => _edit(i),
                  onRemove: () => _remove(i),
                ),
            ],
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Total ${formatDuration(totalMinutes(_steps))}',
                style: RestType.sans(
                  15,
                  color: RestPalette.primary,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _addFromLibrary,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add step'),
              style: OutlinedButton.styleFrom(
                foregroundColor: RestPalette.primary,
                side: const BorderSide(color: RestPalette.border),
                backgroundColor: RestPalette.background,
                shape: const StadiumBorder(),
                minimumSize: const Size(44, 44),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    super.key,
    required this.index,
    required this.step,
    required this.onTap,
    required this.onRemove,
  });

  final int index;
  final RoutineStepData step;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: RestPalette.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.drag_indicator, color: RestPalette.accent),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Semantics(
                      label: '${step.title}, ${formatDuration(stepMinutes(step))}. Tap to edit.',
                      excludeSemantics: true,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              step.title,
                              style: RestType.sans(15, weight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            formatDuration(stepMinutes(step)),
                            style: RestType.sans(14, color: RestPalette.accent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Remove ${step.title}',
              onPressed: onRemove,
              icon: const Icon(Icons.close, color: RestPalette.accent),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            ),
          ],
        ),
      );
}

class _StepDialog extends StatefulWidget {
  const _StepDialog({required this.initial, required this.title});

  final RoutineStepData initial;
  final String title;

  @override
  State<_StepDialog> createState() => _StepDialogState();
}

class _StepDialogState extends State<_StepDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial.title);
  late int _minutes = widget.initial.durationMin ?? defaultStepMinutes;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _valid => _name.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: RestPalette.background,
        title: Text(widget.title, style: RestType.serif(26)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              maxLength: 40,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.outlined(
                  tooltip: 'Shorter',
                  onPressed: _minutes <= minStepMinutes
                      ? null
                      : () => setState(() => _minutes -= 5),
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Text(
                    formatDuration(_minutes),
                    textAlign: TextAlign.center,
                    style: RestType.serif(26),
                  ),
                ),
                IconButton.outlined(
                  tooltip: 'Longer',
                  onPressed: _minutes >= maxStepMinutes
                      ? null
                      : () => setState(() => _minutes += 5),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _valid
                ? () => Navigator.pop(
                      context,
                      RoutineStepData(
                        title: _name.text.trim(),
                        durationMin: _minutes,
                      ),
                    )
                : null,
            child: const Text('Save'),
          ),
        ],
      );
}
