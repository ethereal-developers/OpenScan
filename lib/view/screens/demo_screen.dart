import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openscan/l10n/app_localizations.dart';
import 'package:openscan/core/settings/app_settings.dart';
import 'package:openscan/core/theme/appTheme.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/core/theme/os_typography.dart';
import 'package:openscan/view/Widgets/demo/slide_dots.dart';
import 'package:openscan/view/Widgets/demo/slide_item.dart';
import 'package:permission_handler/permission_handler.dart';

/// The tutorial: one slide per step of making a document, each showing a
/// working miniature of the screen it describes, ending on the permission
/// the app cannot work without.
///
/// Fixed dark, like the camera it hands off into.
class DemoScreen extends StatefulWidget {
  DemoScreen({this.showSkip = true});

  /// False when the tutorial is opened deliberately from Settings rather
  /// than on first launch — there is nothing to skip, only to go back from,
  /// and it must not ask for camera permission again at the end.
  final bool showSkip;

  @override
  _DemoScreenState createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  bool get _onLastSlide => _currentPage == slideList.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_onLastSlide) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: OSMotion.standard,
      curve: OSMotion.emphasizedDecel,
    );
  }

  Future<void> _finish() async {
    if (widget.showSkip) await Permission.camera.request();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // The screen is fixed dark whatever the app's theme mode, so everything
    // it paints — accent included — comes from the dark theme. Handing it
    // the light accent on a near-black ground is how the two drifted apart
    // before.
    return Theme(
      data: AppTheme.dark(AppSettings.instance.accent),
      child: Builder(builder: _body),
    );
  }

  Widget _body(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final onAccent = Theme.of(context).colorScheme.onPrimary;
    final l10n = AppLocalizations.of(context)!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: OSColors.chromeBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: OSColors.chromeBackground,
        body: SafeArea(
          child: Column(
            children: [
              // Back on the left, Skip on the right: the two are opposite
              // affordances and were sharing a right-aligned slot, which
              // put the back arrow in the corner furthest from the thumb.
              SizedBox(
                height: 48,
                child: widget.showSkip
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _finish,
                          child: Text(l10n.skip,
                              style: OSTypography.label
                                  .copyWith(color: OSColors.chromeMuted)),
                        ),
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: OSColors.chromeOnBackground),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: slideList.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) => SlideItem(index),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: OSSpace.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < slideList.length; i++)
                      SlideDots(i == _currentPage),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    OSSpace.xl, OSSpace.lg, OSSpace.xl, OSSpace.xl),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: onAccent,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(OSRadius.card),
                      ),
                    ),
                    onPressed: _next,
                    child: Text(_onLastSlide
                        ? (widget.showSkip
                            ? l10n.allow_camera_access
                            : l10n.done)
                        : l10n.next),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
