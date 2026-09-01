import 'package:flutter/material.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';

/// The screen each tutorial slide teaches, drawn rather than screenshotted.
///
/// A screenshot would go stale the first time a screen changes, ships as a
/// megabyte of PNG per locale, and cannot follow the user's accent. These
/// are miniatures of the real screens built from the same tokens the real
/// screens use, so an accent swap moves them too, and they animate the one
/// gesture the slide is trying to teach.
enum DemoMockup { scan, pages, adjust, organise, export, privacy }

/// Every mockup is laid out against this fixed design size and then scaled
/// to whatever room the slide has. Drawing at one known size keeps the
/// internal geometry plain arithmetic instead of nested LayoutBuilders.
const Size _design = Size(232, 464);

/// A miniature of one app screen, scaled to fit its slot.
///
/// The scaling is deliberate: the mockup is a picture of the UI, not text
/// to read, so it is pinned to [_design] and shrunk as a whole. That also
/// keeps it out of the text-scale path — a user at 200% text gets bigger
/// slide copy, not a mockup that bursts its bounds.
class DemoMockupView extends StatelessWidget {
  const DemoMockupView(this.mockup, {Key? key}) : super(key: key);

  final DemoMockup mockup;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: _design.width,
          height: _design.height,
          child: _PhoneFrame(child: _screen(context)),
        ),
      ),
    );
  }

  Widget _screen(BuildContext context) {
    switch (mockup) {
      case DemoMockup.scan:
        return const _ScanScreen();
      case DemoMockup.pages:
        return const _PagesScreen();
      case DemoMockup.adjust:
        return const _AdjustScreen();
      case DemoMockup.organise:
        return const _OrganiseScreen();
      case DemoMockup.export:
        return const _ExportScreen();
      case DemoMockup.privacy:
        return const _PrivacyScreen();
    }
  }
}

/// The device the miniatures sit in. The outline is what keeps a dark-mode
/// mockup from dissolving into the demo screen's near-black background.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF3A342C), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

/// The themed palette a mockup of a *themed* screen (library, document,
/// export) paints with, so those miniatures follow light/dark like the real
/// screens do. Camera, crop and filter are fixed dark in the real app and
/// use the `OSColors.chrome*` constants directly instead.
OSColors _os(BuildContext context) =>
    Theme.of(context).extension<OSColors>()!;

Color _accent(BuildContext context) => Theme.of(context).colorScheme.primary;

/// A block standing in for a line of text. Real strings inside a miniature
/// would be unreadable at this scale and would need translating for six
/// locales to say nothing the slide's own copy does not already say.
class _TextBar extends StatelessWidget {
  const _TextBar(this.width, {this.height = 5, required this.color});

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(height / 2),
        ),
      );
}

/// A small glyph in dark camera chrome.
class _ChromeIcon extends StatelessWidget {
  const _ChromeIcon(this.icon, {this.size = 13});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) =>
      Icon(icon, size: size, color: OSColors.chromeOnBackground);
}

/// Stands in for the camera's view of a desk with a page on it. Nothing
/// here is a photograph; it is two washes and a sheet, which is all the
/// eye needs to read "page on a surface" at 200px wide.
class _Scene extends StatelessWidget {
  const _Scene({this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4A423A), Color(0xFF2C2722)],
            ),
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}

/// The sheet of paper the detection quad locks onto.
class _Page extends StatelessWidget {
  const _Page({this.lines = 5});

  final int lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2EA),
        borderRadius: BorderRadius.circular(2),
        boxShadow: const [
          BoxShadow(color: Color(0x55000000), blurRadius: 8, offset: Offset(2, 4)),
        ],
      ),
      padding: const EdgeInsets.all(9),
      // Ruled as a fraction of the sheet, so the same widget reads as a
      // page whether it is a thumbnail or fills the crop screen.
      child: LayoutBuilder(
        builder: (context, box) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TextBar(box.maxWidth * 0.45,
                height: 4, color: const Color(0xFF9A9088)),
            SizedBox(height: box.maxHeight * 0.05),
            for (int i = 0; i < lines; i++) ...[
              _TextBar(box.maxWidth * (i.isEven ? 0.92 : 0.68),
                  height: 3, color: const Color(0xFFC9C1B8)),
              SizedBox(height: box.maxHeight * 0.035),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Scan — the quad finds the page and locks
// ---------------------------------------------------------------------------

/// Loops the one thing that makes the app work: edges found, edges locked,
/// shutter fires on its own. The quad turns green exactly where the real
/// [LiveQuadPainter] turns green, because that colour is the app's signal
/// that a capture is imminent.
class _ScanScreen extends StatefulWidget {
  const _ScanScreen();

  @override
  State<_ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<_ScanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);

    return ColoredBox(
      color: OSColors.chromeBackground,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          // Found at 25%, locked from 55%, flash at 80%.
          final found = t > 0.25;
          final locked = t > 0.55;
          final flash = t > 0.80 && t < 0.86;

          return Column(
            children: [
              _cameraTopBar(context, accent),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _Scene(
                      child: Center(
                        child: Transform.rotate(
                          angle: -0.045,
                          child: SizedBox(
                            width: 118,
                            height: 152,
                            child: Stack(
                              children: [
                                const Positioned.fill(child: _Page()),
                                Positioned.fill(
                                  child: AnimatedOpacity(
                                    opacity: found ? 1 : 0,
                                    duration: OSMotion.selection,
                                    child: CustomPaint(
                                      painter: _QuadPainter(
                                        color: locked
                                            ? Colors.greenAccent
                                            : accent,
                                        strokeWidth: locked ? 3 : 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (flash)
                      const Positioned.fill(
                        child: ColoredBox(color: Color(0xCCFFFFFF)),
                      ),
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: found ? 1 : 0,
                          duration: OSMotion.selection,
                          child: _detectedPill(context, accent),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: locked ? 1 : 0,
                          duration: OSMotion.selection,
                          child: const _TextBar(52,
                              height: 5, color: OSColors.chromeOnBackground),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _bottomBar(context, accent, pulse: locked),
            ],
          );
        },
      ),
    );
  }

  Widget _detectedPill(BuildContext context, Color accent) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(OSRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded,
                size: 9, color: Theme.of(context).colorScheme.onPrimary),
            const SizedBox(width: 4),
            _TextBar(46,
                height: 4, color: Theme.of(context).colorScheme.onPrimary),
          ],
        ),
      );
}

/// The camera's top bar: torch, the auto-capture toggle (filled, because
/// auto-capture is on by default), grid and lens switch.
Widget _cameraTopBar(BuildContext context, Color accent) => Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Row(
        children: [
          const _ChromeIcon(Icons.flash_off_rounded),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            child: Icon(Icons.auto_awesome_rounded,
                size: 11, color: Theme.of(context).colorScheme.onPrimary),
          ),
          const Spacer(),
          const _ChromeIcon(Icons.grid_3x3_rounded),
          const SizedBox(width: 10),
          const _ChromeIcon(Icons.cameraswitch_rounded),
        ],
      ),
    );

/// The camera's bottom bar: gallery, shutter, Done. [pulse] rings the
/// shutter the way the real one reacts when auto-capture is about to fire.
Widget _bottomBar(BuildContext context, Color accent,
    {bool pulse = false, int count = 0}) {
  return Container(
    color: OSColors.chromeBackground,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const _ChromeIcon(Icons.photo_library_rounded, size: 15),
        AnimatedContainer(
          duration: OSMotion.shutter,
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: OSColors.chromeOnBackground,
            border: Border.all(
              color: pulse ? Colors.greenAccent : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        Row(
          children: [
            _TextBar(20, height: 5, color: count > 0
                ? OSColors.chromeOnBackground
                : OSColors.chromeMuted),
            const SizedBox(width: 4),
            if (count > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(OSRadius.pill),
                ),
                child: Text('$count',
                    style: TextStyle(
                      fontSize: 9,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onPrimary,
                    )),
              )
            else
              const _ChromeIcon(Icons.check_rounded, size: 12),
          ],
        ),
      ],
    ),
  );
}

/// Strokes the four-sided guide the live preview draws over a detected
/// page, inset so the stroke sits on the sheet rather than outside it.
class _QuadPainter extends CustomPainter {
  _QuadPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // Inset by the stroke so the guide sits on the sheet, not beyond it.
    // The page it covers is drawn pre-rotated, which is where the "held at
    // an angle" look comes from.
    final path = Path()
      ..addRect(Rect.fromLTWH(2, 2, size.width - 4, size.height - 4));

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_QuadPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

// ---------------------------------------------------------------------------
// 2. Pages — shots pile up into one document
// ---------------------------------------------------------------------------

/// Counts the Done badge up while thumbnails stack in the corner, which is
/// the only cue that tells a new user the app is collecting pages rather
/// than taking one photo and stopping.
class _PagesScreen extends StatefulWidget {
  const _PagesScreen();

  @override
  State<_PagesScreen> createState() => _PagesScreenState();
}

class _PagesScreenState extends State<_PagesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);

    return ColoredBox(
      color: OSColors.chromeBackground,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          // Three captures over the loop, then a beat holding at three.
          final count = (_c.value * 4).floor().clamp(0, 3);

          return Column(
            children: [
              _cameraTopBar(context, accent),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _Scene(
                      child: Center(
                        child: Transform.rotate(
                          angle: 0.04,
                          child: SizedBox(
                            width: 112,
                            height: 146,
                            child: Stack(
                              children: [
                                const Positioned.fill(child: _Page(lines: 4)),
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _QuadPainter(
                                        color: accent, strokeWidth: 2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // The growing stack of captured pages.
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: SizedBox(
                        width: 44,
                        height: 52,
                        child: Stack(
                          children: [
                            for (int i = 0; i < count; i++)
                              Positioned(
                                left: i * 4.0,
                                top: i * 3.0,
                                child: Container(
                                  width: 30,
                                  height: 39,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F2EA),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(
                                        color: OSColors.chromeBackground,
                                        width: 1),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _bottomBar(context, accent, count: count),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Adjust — drag a corner, pick a filter
// ---------------------------------------------------------------------------

/// The crop screen with a finger walking one corner handle back onto the
/// page. Corner-dragging is the only gesture in the app a user will not
/// discover by tapping, so it is the one worth animating.
class _AdjustScreen extends StatefulWidget {
  const _AdjustScreen();

  @override
  State<_AdjustScreen> createState() => _AdjustScreenState();
}

class _AdjustScreenState extends State<_AdjustScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);

    return ColoredBox(
      color: OSColors.chromeBackground,
      child: Column(
        children: [
          // "Adjust edges", with Next in the accent like the real bar.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                const _ChromeIcon(Icons.close_rounded, size: 12),
                const Spacer(),
                const _TextBar(44,
                    height: 5, color: OSColors.chromeOnBackground),
                const Spacer(),
                _TextBar(18, height: 5, color: accent),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final t = Curves.easeInOut.transform(_c.value);
                  return LayoutBuilder(
                    builder: (context, box) => Stack(
                      children: [
                        Positioned.fill(
                          child: _Scene(
                            child: Center(
                              child: Transform.rotate(
                                angle: -0.05,
                                child: SizedBox(
                                  width: box.maxWidth * 0.74,
                                  height: box.maxHeight * 0.80,
                                  child: const _Page(lines: 7),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _CropQuadPainter(
                              accent: accent,
                              // The dragged corner travels from off the
                              // page back onto it.
                              drag: t,
                            ),
                          ),
                        ),
                        // The fingertip on the handle being moved.
                        Positioned(
                          left: box.maxWidth * (0.10 + 0.10 * t) - 9,
                          top: box.maxHeight * (0.16 - 0.10 * t) - 9,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.30),
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // Automatic crop / No crop / Rotate.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(Icons.auto_awesome_rounded, size: 11, color: accent),
                  const SizedBox(width: 4),
                  _TextBar(30, height: 4, color: accent),
                ]),
                const Row(children: [
                  _ChromeIcon(Icons.crop_free_rounded, size: 11),
                  SizedBox(width: 4),
                  _TextBar(20, height: 4, color: OSColors.chromeOnBackground),
                ]),
                const Row(children: [
                  _ChromeIcon(Icons.rotate_right_rounded, size: 11),
                  SizedBox(width: 4),
                  _TextBar(18, height: 4, color: OSColors.chromeOnBackground),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The editable quad: four corner handles and four edge handles, with the
/// top-left corner offset by [drag] so it can be animated back into place.
class _CropQuadPainter extends CustomPainter {
  _CropQuadPainter({required this.accent, required this.drag});

  final Color accent;
  final double drag;

  @override
  void paint(Canvas canvas, Size size) {
    final topLeft = Offset(
      size.width * (0.10 + 0.10 * drag),
      size.height * (0.16 - 0.10 * drag),
    );
    final corners = [
      topLeft,
      Offset(size.width * 0.92, size.height * 0.08),
      Offset(size.width * 0.88, size.height * 0.93),
      Offset(size.width * 0.08, size.height * 0.88),
    ];

    final path = Path()..addPolygon(corners, true);
    canvas.drawPath(
      path,
      Paint()
        ..color = accent
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke,
    );

    final fill = Paint()..color = accent.withValues(alpha: 0.25);
    final ring = Paint()
      ..color = accent
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    for (final c in corners) {
      canvas.drawCircle(c, 5, fill);
      canvas.drawCircle(c, 5, ring);
    }
    // Edge midpoints, drawn smaller, exactly as the crop screen does.
    for (int i = 0; i < corners.length; i++) {
      final mid = Offset.lerp(corners[i], corners[(i + 1) % 4], 0.5)!;
      canvas.drawCircle(mid, 3.5, ring);
    }
  }

  @override
  bool shouldRepaint(_CropQuadPainter old) =>
      old.drag != drag || old.accent != accent;
}

// ---------------------------------------------------------------------------
// 4. Organise — hold a page to reorder
// ---------------------------------------------------------------------------

/// The document screen, with one page lifted and swapping with its
/// neighbour. Long-press-to-reorder is invisible until someone shows you,
/// so the miniature shows you.
class _OrganiseScreen extends StatefulWidget {
  const _OrganiseScreen();

  @override
  State<_OrganiseScreen> createState() => _OrganiseScreenState();
}

class _OrganiseScreenState extends State<_OrganiseScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final os = _os(context);
    final accent = _accent(context);

    return ColoredBox(
      color: os.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title bar: back, name, rename pencil, overflow.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
            child: Row(
              children: [
                Icon(Icons.arrow_back_rounded, size: 13, color: os.onSurface),
                const SizedBox(width: 8),
                _TextBar(74, height: 6, color: os.onSurface),
                const Spacer(),
                Icon(Icons.edit_rounded, size: 11, color: os.onSurfaceVariant),
                const SizedBox(width: 8),
                Icon(Icons.more_vert_rounded,
                    size: 11, color: os.onSurfaceVariant),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 6, 12, 12),
            child: _TextBar(96, height: 4, color: os.onSurfaceVariant),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => _grid(os, accent),
              ),
            ),
          ),
          // Add pages / Export.
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: os.surfaceVariant,
                      borderRadius: BorderRadius.circular(OSRadius.card),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 11, color: os.onSurface),
                          const SizedBox(width: 4),
                          _TextBar(34, height: 4, color: os.onSurface),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(OSRadius.card),
                    ),
                    child: Center(
                      child: _TextBar(26,
                          height: 4,
                          color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Six page cards in the real 3-across grid. Card 2 lifts, slides into
  /// slot 3, and the two swap numbers — one full reorder per loop.
  Widget _grid(OSColors os, Color accent) {
    const cols = 3;
    const gap = 6.0;
    final t = _c.value;

    // Lift 15-35%, travel 35-65%, settle 65-80%, rest.
    final lift = t < 0.15
        ? 0.0
        : t < 0.35
            ? (t - 0.15) / 0.20
            : t < 0.80
                ? 1.0
                : 0.0;
    final travel = t < 0.35
        ? 0.0
        : t < 0.65
            ? Curves.easeInOut.transform((t - 0.35) / 0.30)
            : 1.0;
    final swapped = t >= 0.35;

    return LayoutBuilder(
      builder: (context, box) {
        final cardW = (box.maxWidth - gap * (cols - 1)) / cols;
        final cardH = cardW * 1.3;

        Offset slot(int i) => Offset(
              (i % cols) * (cardW + gap),
              (i ~/ cols) * (cardH + gap),
            );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            for (int i = 0; i < 6; i++)
              if (i != 1)
                Positioned(
                  left: slot(i == 2 && swapped ? 1 : i).dx,
                  top: slot(i == 2 && swapped ? 1 : i).dy,
                  child: _pageCard(
                    os,
                    cardW,
                    cardH,
                    // Numbers follow position, not identity — a reorder
                    // renumbers the document.
                    i == 2 && swapped ? 2 : i + 1,
                  ),
                ),
            // The held card, drawn last so it floats above the rest.
            Positioned(
              left: Offset.lerp(slot(1), slot(2), travel)!.dx,
              top: Offset.lerp(slot(1), slot(2), travel)!.dy - 4 * lift,
              child: Transform.scale(
                scale: 1 + 0.08 * lift,
                child: _pageCard(
                  os,
                  cardW,
                  cardH,
                  swapped ? 3 : 2,
                  lifted: lift > 0,
                  accent: accent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _pageCard(OSColors os, double w, double h, int number,
      {bool lifted = false, Color? accent}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2EA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: lifted ? (accent ?? os.outline) : os.outline,
          width: lifted ? 1.5 : 1,
        ),
        boxShadow: lifted
            ? const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                )
              ]
            : null,
      ),
      padding: const EdgeInsets.all(5),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < 4; i++) ...[
                _TextBar(i.isEven ? w * 0.6 : w * 0.42,
                    height: 2.5, color: const Color(0xFFCBC3BA)),
                const SizedBox(height: 4),
              ],
            ],
          ),
          // The page-number badge in the corner.
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 13,
              height: 13,
              decoration: const BoxDecoration(
                color: Color(0xCC2A251E),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text('$number',
                  style: const TextStyle(
                    fontSize: 7,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Export — quality, then Save or Share
// ---------------------------------------------------------------------------

/// The export sheet over a dimmed document screen, cycling the quality
/// chips so it is clear they are a choice and not a label.
class _ExportScreen extends StatefulWidget {
  const _ExportScreen();

  @override
  State<_ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<_ExportScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final os = _os(context);
    final accent = _accent(context);
    final onAccent = Theme.of(context).colorScheme.onPrimary;

    return ColoredBox(
      color: os.surface,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final selected = (_c.value * 4).floor().clamp(0, 3);

          return Stack(
            children: [
              // The document screen behind, scrimmed by the sheet.
              Positioned.fill(
                child: ColoredBox(color: os.surface, child: _behind(os)),
              ),
              const Positioned.fill(
                child: ColoredBox(color: Color(0x8C000000)),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: os.surfaceVariant,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(OSRadius.sheet)),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 26,
                          height: 3,
                          decoration: BoxDecoration(
                            color: os.outline,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _TextBar(88, height: 6, color: os.onSurface),
                      const SizedBox(height: 10),
                      // PDF / JPG / PNG.
                      Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: os.surface,
                          borderRadius: BorderRadius.circular(OSRadius.chip),
                          border: Border.all(color: os.outline),
                        ),
                        child: Row(
                          children: [
                            for (int i = 0; i < 3; i++)
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: i == 0 ? accent : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: _TextBar(16,
                                      height: 4,
                                      color: i == 0
                                          ? onAccent
                                          : os.onSurfaceVariant),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _TextBar(26, height: 3, color: os.onSurfaceVariant),
                      const SizedBox(height: 6),
                      // The four quality chips, one selected at a time.
                      Row(
                        children: [
                          for (int i = 0; i < 4; i++) ...[
                            Expanded(
                              child: AnimatedContainer(
                                duration: OSMotion.selection,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: i == selected
                                      ? accent.withValues(alpha: 0.18)
                                      : os.surface,
                                  borderRadius:
                                      BorderRadius.circular(OSRadius.chip),
                                  border: Border.all(
                                    color:
                                        i == selected ? accent : os.outline,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _TextBar(20,
                                        height: 3.5,
                                        color: i == selected
                                            ? accent
                                            : os.onSurface),
                                    const SizedBox(height: 3),
                                    _TextBar(14,
                                        height: 3,
                                        color: os.onSurfaceVariant),
                                  ],
                                ),
                              ),
                            ),
                            if (i < 3) const SizedBox(width: 5),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Page size, with its value in the accent.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _TextBar(34, height: 5, color: os.onSurface),
                          Row(children: [
                            _TextBar(12, height: 5, color: accent),
                            const SizedBox(width: 3),
                            Icon(Icons.chevron_right_rounded,
                                size: 10, color: accent),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Save / Share.
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 24,
                              decoration: BoxDecoration(
                                color: os.surface,
                                borderRadius:
                                    BorderRadius.circular(OSRadius.card),
                                border: Border.all(color: os.outline),
                              ),
                              alignment: Alignment.center,
                              child: _TextBar(22,
                                  height: 4, color: os.onSurface),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 24,
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius:
                                    BorderRadius.circular(OSRadius.card),
                              ),
                              alignment: Alignment.center,
                              child:
                                  _TextBar(26, height: 4, color: onAccent),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// A hint of the page grid behind the sheet, so the sheet reads as a
  /// sheet rather than a screen.
  Widget _behind(OSColors os) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 40, 12, 0),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (int i = 0; i < 6; i++)
              Container(
                width: 62,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F2EA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: os.outline),
                ),
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int j = 0; j < 4; j++) ...[
                      _TextBar(j.isEven ? 38 : 26,
                          height: 2.5, color: const Color(0xFFCBC3BA)),
                      const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// 6. Privacy — nothing leaves the phone
// ---------------------------------------------------------------------------

/// The one slide with no screen to show, because the point is what the app
/// does *not* do. A phone holding the document, and the network path out
/// of it struck through.
class _PrivacyScreen extends StatelessWidget {
  const _PrivacyScreen();

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);

    return ColoredBox(
      color: OSColors.chromeBackground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: const Color(0xFF221E18),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF3A342C), width: 2),
              ),
              child: Icon(Icons.lock_rounded, size: 50, color: accent),
            ),
            const SizedBox(height: 32),
            // No cloud, no accounts, no tracking.
            for (final icon in [
              Icons.cloud_off_rounded,
              Icons.person_off_rounded,
              Icons.visibility_off_rounded,
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: OSColors.chromeMuted),
                    const SizedBox(width: 10),
                    const _TextBar(84, height: 6, color: OSColors.chromeMuted),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
