import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/core/theme/os_typography.dart';
import 'package:openscan/view/Widgets/demo/slide_dots.dart';
import 'package:openscan/view/Widgets/demo/slide_item.dart';
import 'package:permission_handler/permission_handler.dart';

/// Onboarding. Fixed dark, like the camera it hands off into, and only as
/// long as it needs to be: two things worth knowing, then the permission
/// the app cannot work without.
class DemoScreen extends StatefulWidget {
  DemoScreen({this.showSkip = true});

  /// False when the tutorial is opened deliberately from Settings rather
  /// than on first launch — there is nothing to skip, only to go back from,
  /// and it must not ask for camera permission again at the end.
  final bool? showSkip;

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
    if (widget.showSkip!) await Permission.camera.request();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final onAccent = Theme.of(context).colorScheme.onPrimary;

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
              Align(
                alignment: Alignment.centerRight,
                child: widget.showSkip!
                    ? TextButton(
                        onPressed: _finish,
                        child: Text('Skip',
                            style: OSTypography.label
                                .copyWith(color: OSColors.chromeMuted)),
                      )
                    : IconButton(
                        alignment: Alignment.centerLeft,
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: OSColors.chromeOnBackground),
                        onPressed: () => Navigator.pop(context),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < slideList.length; i++)
                    SlideDots(i == _currentPage),
                ],
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
                        ? (widget.showSkip! ? 'Allow camera access' : 'Done')
                        : 'Next'),
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
