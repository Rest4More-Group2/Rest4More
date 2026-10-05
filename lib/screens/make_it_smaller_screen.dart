import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class MakeItSmallerScreen extends StatefulWidget {
  const MakeItSmallerScreen({
    super.key,
    this.originalMinutes = 20,
    this.smallerMinutes = 5,
  }) : assert(originalMinutes > 0),
       assert(smallerMinutes > 0 && smallerMinutes <= originalMinutes);

  final int originalMinutes;
  final int smallerMinutes;

  @override
  State<MakeItSmallerScreen> createState() =>
      _MakeItSmallerScreenState();
}

class _MakeItSmallerScreenState extends State<MakeItSmallerScreen> {
  // The recommended alternative is selected when the page opens.
  bool _smallerSelected = true;

  int get _selectedMinutes => _smallerSelected
      ? widget.smallerMinutes
      : widget.originalMinutes;

  static const _background = Color(0xFFFAF8F5);
  static const _surface = Color(0xFFECE7DB);
  static const _ink = Color(0xFF554237);
  static const _primary = Color(0xFF7D573D);
  static const _accent = Color(0xFFAA7657);
  static const _border = Color(0xFFE5DCCD);

  TextStyle _sans(
    double size, {
    Color color = _ink,
    FontWeight weight = FontWeight.w400,
  }) {
    return GoogleFonts.manrope(
      fontSize: size,
      color: color,
      fontWeight: weight,
      height: 1.5,
    );
  }

  TextStyle _serif(
    double size, {
    FontWeight weight = FontWeight.w400,
  }) {
    return GoogleFonts.cormorantGaramond(
      fontSize: size,
      color: _ink,
      fontWeight: weight,
      height: 1.12,
    );
  }

  Widget _option({
    required String label,
    required int minutes,
    required double scale,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final radius = BorderRadius.circular(18 * scale);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? _surface : _background,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? _primary : _border,
            // Same thickness prevents content shifting on selection.
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: EdgeInsets.all(19 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: _sans(
                          11 * scale,
                          color: selected ? _primary : _accent,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox.square(
                      dimension: 16 * scale,
                      child: selected
                          ? Icon(
                              Icons.wb_sunny_outlined,
                              size: 16 * scale,
                              color: _primary,
                            )
                          : null,
                    ),
                  ],
                ),
                SizedBox(height: 12 * scale),
                Text(
                  '$minutes minute quiet moment',
                  style: _serif(
                    22 * scale,
                    weight: selected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: _background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth > 520
                  ? 520.0
                  : constraints.maxWidth;

              final scale =
                  (width / 390).clamp(0.85, 1.34).toDouble();

              return SingleChildScrollView(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: width,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        24 * scale,
                        12 * scale,
                        24 * scale,
                        32 * scale,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.arrow_back,
                                size: 16 * scale,
                              ),
                              label: const Text('Back'),
                              style: TextButton.styleFrom(
                                foregroundColor: _primary,
                                padding: EdgeInsets.zero,
                                textStyle: _sans(14 * scale),
                                minimumSize: const Size(48, 48),
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                          ),
                          SizedBox(height: 4 * scale),
                          Text(
                            'Make it smaller',
                            style: _serif(32 * scale),
                          ),
                          SizedBox(height: 36 * scale),
                          Text(
                            'Short on time or energy? That’s okay. '
                            'You can still take a small step.',
                            style: _sans(15 * scale),
                          ),
                          SizedBox(height: 26 * scale),

                          // Original option.
                          _option(
                            label: 'ORIGINAL OPTION',
                            minutes: widget.originalMinutes,
                            scale: scale,
                            selected: !_smallerSelected,
                            onTap: () {
                              setState(() {
                                _smallerSelected = false;
                              });
                            },
                          ),
                          SizedBox(height: 16 * scale),

                          // Smaller option.
                          _option(
                            label: 'RECOMMENDED ALTERNATIVE',
                            minutes: widget.smallerMinutes,
                            scale: scale,
                            selected: _smallerSelected,
                            onTap: () {
                              setState(() {
                                _smallerSelected = true;
                              });
                            },
                          ),
                          SizedBox(height: 40 * scale),

                          FilledButton(
                            onPressed: () {
                              Navigator.pop<int>(
                                context,
                                _selectedMinutes,
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: _background,
                              elevation: 0,
                              minimumSize: Size(
                                double.infinity,
                                52 * scale,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 20 * scale,
                                vertical: 13 * scale,
                              ),
                              shape: const StadiumBorder(),
                              textStyle: _sans(
                                16 * scale,
                                weight: FontWeight.w600,
                              ),
                            ),
                            child: Text(
                              _smallerSelected
                                  ? 'Start $_selectedMinutes-minute version'
                                  : 'Keep $_selectedMinutes-minute version',
                            ),
                          ),
                          SizedBox(height: 8 * scale),

                          TextButton(
                            onPressed: () {
                              Navigator.pop<int>(
                                context,
                                widget.originalMinutes,
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: _primary,
                              minimumSize: const Size(48, 48),
                              textStyle: _sans(
                                14 * scale,
                                weight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Keep the original'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}