import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rest4more/data/moments/moment_plans.dart';
import 'package:rest4more/providers/repository_providers.dart';

import 'evening_screen.dart';
import 'morning_screen.dart';
import 'today_screen.dart' show RestPalette;

/// Avondpagina met het bewaarde plan. Opslaan schrijft het plan weg en sluit
/// de pagina; mislukt dat, dan blijft de pagina open met de invoer erin.
class SavedEveningScreen extends ConsumerWidget {
  const SavedEveningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.read(momentPlanStoreProvider);
    return _SavedPage(
      load: () async => await store.loadEvening() ?? EveningPlan.initial(),
      builder: (plan) => EveningScreen(
        initial: plan,
        onSave: (p) => saveAndClose(context, 'Evening', () => store.saveEvening(p)),
      ),
    );
  }
}

class SavedMorningScreen extends ConsumerWidget {
  const SavedMorningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.read(momentPlanStoreProvider);
    return _SavedPage(
      load: () async => await store.loadMorning() ?? MorningPlan.initial(),
      builder: (plan) => MorningScreen(
        initial: plan,
        onSave: (p) => saveAndClose(context, 'Morning', () => store.saveMorning(p)),
      ),
    );
  }
}

/// Bewaart en meldt het resultaat. Toont "saved" pas als het wegschrijven echt
/// gelukt is.
Future<void> saveAndClose(
  BuildContext context,
  String name,
  Future<void> Function() save,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  try {
    await save();
  } on Object {
    messenger.showSnackBar(
      SnackBar(content: Text('Could not save your $name. Please try again.')),
    );
    return;
  }
  messenger.showSnackBar(SnackBar(content: Text('$name saved')));
  navigator.pop();
}

class _SavedPage<T> extends StatefulWidget {
  const _SavedPage({required this.load, required this.builder});

  final Future<T> Function() load;
  final Widget Function(T plan) builder;

  @override
  State<_SavedPage<T>> createState() => _SavedPageState<T>();
}

class _SavedPageState<T> extends State<_SavedPage<T>> {
  late Future<T> _future = widget.load();

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasData) return widget.builder(snapshot.data as T);
          return Scaffold(
            backgroundColor: RestPalette.background,
            body: Center(
              child: snapshot.hasError
                  ? TextButton(
                      onPressed: () => setState(() => _future = widget.load()),
                      child: const Text('Could not load. Try again'),
                    )
                  : const CircularProgressIndicator(color: RestPalette.primary),
            ),
          );
        },
      );
}
