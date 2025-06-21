import 'package:flutter/material.dart';
import 'package:openscan/core/theme/appTheme.dart';

class HoveringSnackBar extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color? borderColor;
  final Widget? icon;
  final Duration duration;
  final VoidCallback? onDismiss;
  final SnackBarAction? action;

  const HoveringSnackBar({
    Key? key,
    required this.message,
    this.backgroundColor = const Color(0xFF222222),
    this.borderColor,
    this.icon,
    this.duration = const Duration(seconds: 2),
    this.onDismiss,
    this.action,
  }) : super(key: key);

  @override
  State<HoveringSnackBar> createState() => _HoveringSnackBarState();
}

class _HoveringSnackBarState extends State<HoveringSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();

    // Auto-dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
            _dismiss();
          }
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Material(
                  elevation: 4,
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        bottom: BorderSide(
                          color: widget.borderColor ?? Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            widget.icon!,
                            const SizedBox(width: 10),
                          ],
                          Flexible(
                            child: Text(
                              widget.message,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.action != null) ...[
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                widget.action!.onPressed();
                                _dismiss();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                widget.action!.label,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Utility class to show hovering snackbars
class HoveringSnackBarHelper {
  static const Color _snackBarBackground = Color(0xFF222222);

  static void show(
    BuildContext context, {
    required String message,
    Widget? icon,
    Color? borderColor,
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => HoveringSnackBar(
        message: message,
        backgroundColor: _snackBarBackground,
        icon: icon,
        borderColor: borderColor,
        duration: duration,
        action: action,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);
  }

  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    show(
      context,
      message: message,
      icon: const Icon(Icons.check_circle, color: Colors.green, size: 20),
      borderColor: Colors.green,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    show(
      context,
      message: message,
      icon: Icon(Icons.error, color: AppTheme.secondaryColor, size: 20),
      borderColor: AppTheme.secondaryColor,
      duration: duration,
      action: action,
    );
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    show(
      context,
      message: message,
      icon: Icon(Icons.warning, color: AppTheme.secondaryColor, size: 20),
      borderColor: AppTheme.secondaryColor,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    show(
      context,
      message: message,
      icon: const Icon(Icons.info, color: Colors.white, size: 20),
      borderColor: Colors.transparent,
      duration: duration,
    );
  }
} 