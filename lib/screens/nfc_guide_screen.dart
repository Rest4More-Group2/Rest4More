import 'package:flutter/material.dart';

import 'today_screen.dart' show RestPalette, RestType;

/// RES-24: visual instructions only. No NFC reads, pairing or session changes.
class NfcGuideScreen extends StatefulWidget {
  const NfcGuideScreen({super.key});

  @override
  State<NfcGuideScreen> createState() => _NfcGuideScreenState();
}

class _NfcGuideScreenState extends State<NfcGuideScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  int _step = 0;
  bool _showTip = false;

  static const _titles = [
    'Meet your NFC card',
    'Pair it once',
    'Start a Tag moment',
    'End your moment',
  ];

  static const _subtitles = [
    'A small, physical reminder to put your phone aside.',
    'Let Rest4More recognize your card before using it.',
    'Choose your apps, then scan your paired card.',
    'Scan the same paired card when you are ready to finish.',
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= _titles.length) return;
    setState(() {
      _step = index;
      _showTip = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      backgroundColor: RestPalette.background,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: FilledButton(
                onPressed: () => _step == _titles.length - 1
                    ? Navigator.of(context).pop()
                    : _goTo(_step + 1),
                style: FilledButton.styleFrom(
                  backgroundColor: RestPalette.primary,
                  foregroundColor: RestPalette.background,
                  minimumSize: const Size(double.infinity, 58),
                  shape: const StadiumBorder(),
                ),
                child: Row(children: [
                  Text(_step == _titles.length - 1 ? 'Got it' : 'Continue',
                      style: RestType.sans(17,
                          color: RestPalette.background,
                          weight: FontWeight.w600)),
                  const Spacer(),
                  Icon(_step == _titles.length - 1
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded),
                ]),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    IconButton(
                      onPressed: () => _step == 0
                          ? Navigator.of(context).pop()
                          : _goTo(_step - 1),
                      tooltip: _step == 0 ? 'Back to NFC tags' : 'Previous step',
                      style: IconButton.styleFrom(
                        backgroundColor: RestPalette.surface,
                        foregroundColor: RestPalette.primary,
                        minimumSize: const Size(44, 44),
                      ),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    const SizedBox(width: 12),
                    Text('NFC card guide',
                        style: RestType.sans(15,
                            color: RestPalette.primary,
                            weight: FontWeight.w600)),
                    const Spacer(),
                    Text('${_step + 1} of ${_titles.length}',
                        style: RestType.sans(13, color: RestPalette.accent)),
                  ]),
                  const SizedBox(height: 22),
                  Row(children: List.generate(_titles.length, (index) =>
                      Expanded(child: Padding(
                        padding: EdgeInsets.only(
                            right: index == _titles.length - 1 ? 0 : 7),
                        child: GestureDetector(
                          onTap: () => _goTo(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 240),
                            height: 5,
                            decoration: BoxDecoration(
                              color: index <= _step
                                  ? RestPalette.primary
                                  : RestPalette.border,
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                      )))),
                  const SizedBox(height: 26),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: Column(
                      key: ValueKey(_step),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_titles[_step], style: RestType.serif(43)),
                        const SizedBox(height: 9),
                        Text(_subtitles[_step],
                            style: RestType.sans(16, color: RestPalette.accent)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _NfcIllustration(
                    key: ValueKey('illustration-$_step'),
                    step: _step,
                    pulse: _pulse,
                    reduceMotion: reduceMotion,
                  ),
                  const SizedBox(height: 23),
                  _instructions(),
                  const SizedBox(height: 15),
                  InkWell(
                    onTap: () => setState(() => _showTip = !_showTip),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(17),
                      decoration: BoxDecoration(
                        border: Border.all(color: RestPalette.border),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(children: [
                        Row(children: [
                          const Icon(Icons.lightbulb_outline,
                              color: RestPalette.primary, size: 22),
                          const SizedBox(width: 11),
                          Expanded(child: Text('Helpful tip',
                              style: RestType.sans(15,
                                  weight: FontWeight.w600))),
                          Icon(_showTip
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: RestPalette.primary),
                        ]),
                        if (_showTip) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_tipForStep(),
                                style: RestType.sans(14,
                                    color: RestPalette.accent)),
                          ),
                        ],
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_step == 3)
                    Text('Need help? Check that NFC is enabled, keep the card '
                        'still, and try another spot on the back of your phone. '
                        'The card must already be paired with Rest4More.',
                        style: RestType.sans(14, color: RestPalette.accent)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _tipForStep() {
    switch (_step) {
      case 0:
        return 'NFC means Near Field Communication. Your phone reads the card '
            'when you hold it close. No camera is needed.';
      case 1:
        return 'The NFC reading area differs between phones. If nothing '
            'happens, slowly move the card near the back of your phone.';
      case 2:
        return 'Only cards you added in Profile → NFC tags can be used '
            'for your Tag moment.';
      default:
        return 'For strict evening routines, you can start the routine '
            'without a card, but ending its blocking requires an NFC scan.';
    }
  }

  Widget _instructions() {
    final steps = switch (_step) {
      0 => const [
          ('A simple ritual', 'Pair the card once, then use it with Tag moments.'),
          ('A deliberate pause', 'Tap your card when it is time to put apps aside.'),
        ],
      1 => const [
          ('Open Profile', 'Choose NFC tags, then tap Add tag.'),
          ('Hold your card nearby', 'Keep it near the NFC reading area on your phone.'),
          ('Look for confirmation', 'Wait until Rest4More says “Tag added.”'),
        ],
      2 => const [
          ('Open Moments', 'Choose Tag and select the apps to set aside.'),
          ('Choose Scan tag to begin', 'Hold your paired card against your phone.'),
          ('Begin your moment', 'Rest4More starts the Tag moment after a valid scan.'),
        ],
      _ => const [
          ('Choose Scan tag to end', 'Open your active Tag moment.'),
          ('Tap your paired card', 'Hold it near the phone’s NFC reading area.'),
          ('Finish intentionally', 'Your Tag moment ends after the valid scan.'),
        ],
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RestPalette.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_step == 0 ? 'How it works' : 'Follow these steps',
              style: RestType.serif(28)),
          const SizedBox(height: 16),
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(height: 19),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                height: 32, width: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: RestPalette.background, shape: BoxShape.circle),
                child: Text('${i + 1}',
                    style: RestType.sans(14,
                        color: RestPalette.primary,
                        weight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(steps[i].$1,
                      style: RestType.sans(15, weight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(steps[i].$2,
                      style: RestType.sans(14, color: RestPalette.accent)),
                ],
              )),
            ]),
          ],
        ],
      ),
    );
  }
}

/// A gentle illustrative animation, not a real NFC scan or connection status.
class _NfcIllustration extends StatelessWidget {
  const _NfcIllustration({
    super.key,
    required this.step,
    required this.pulse,
    required this.reduceMotion,
  });

  final int step;
  final Animation<double> pulse;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) => Container(
    height: 210,
    width: double.infinity,
    decoration: BoxDecoration(
      color: RestPalette.surface,
      borderRadius: BorderRadius.circular(26),
    ),
    clipBehavior: Clip.antiAlias,
    child: AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final amount = reduceMotion ? 0.45 : pulse.value;
        return Stack(alignment: Alignment.center, children: [
          Positioned(
            left: 42, top: 18,
            child: Transform.rotate(
              angle: -0.10,
              child: Container(
                width: 115, height: 174,
                decoration: BoxDecoration(
                  color: RestPalette.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: RestPalette.border, width: 3),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.phone_iphone_rounded,
                        size: 49, color: RestPalette.primary),
                    const SizedBox(height: 12),
                    Text('YOUR PHONE', style: RestType.sans(9,
                        color: RestPalette.accent,
                        weight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 117, top: 29,
            child: Opacity(
              opacity: 0.20 + 0.42 * amount,
              child: Container(
                width: 136 + 22 * amount,
                height: 136 + 22 * amount,
                decoration: BoxDecoration(
                  border: Border.all(color: RestPalette.accent, width: 2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            right: 24 + 6 * amount,
            top: 58 - 5 * amount,
            child: Transform.rotate(
              angle: 0.13,
              child: Container(
                width: 128, height: 91,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: RestPalette.primary,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [BoxShadow(
                    color: Color(0x1A554237),
                    blurRadius: 12, offset: Offset(0, 5),
                  )],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  const Icon(Icons.contactless_rounded,
                      color: RestPalette.background, size: 28),
                  Text('rest for more', style: RestType.sans(10,
                      color: RestPalette.background,
                      weight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
          Positioned(bottom: 12, right: 18,
            child: Text(step == 1 ? 'Hold near phone' :
                        step == 2 ? 'Tap to begin' :
                        step == 3 ? 'Tap to finish' : 'One gentle tap',
                style: RestType.sans(11, color: RestPalette.accent,
                    weight: FontWeight.w600)),
          ),
        ]);
      },
    ),
  );
}
