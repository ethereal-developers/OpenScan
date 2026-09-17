import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openscan/core/models.dart';
import 'package:openscan/core/ocr/ocr_models.dart';
import 'package:openscan/core/ocr/ocr_service.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/core/theme/os_typography.dart';
import 'package:openscan/l10n/app_localizations.dart';
import 'package:openscan/view/Widgets/os/os_components.dart';
import 'package:share_plus/share_plus.dart';

/// The text read off a document's pages: selectable, copyable, shareable.
///
/// Recognition starts as soon as the screen opens and streams in page by
/// page, so a long document is readable from the top while the rest is
/// still being read rather than showing a spinner until all of it is done.
class TextScreen extends StatefulWidget {
  const TextScreen({
    Key? key,
    required this.tableName,
    required this.documentName,
    required this.images,
  }) : super(key: key);

  /// The document's directory name — its identity in the database.
  final String tableName;

  /// What to call the document in the title and the share subject.
  final String documentName;

  /// The pages to read, in order.
  final List<ImageOS> images;

  @override
  State<TextScreen> createState() => _TextScreenState();
}

class _TextScreenState extends State<TextScreen> {
  final OcrService _ocr = OcrService.instance;

  /// Recognized text per page, in page order. Grows as the run proceeds;
  /// a page that failed or came back blank simply never gets an entry.
  final Map<int, OcrPageText> _pages = {};

  int _completed = 0;
  int _failed = 0;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    // Leaving the screen stops the run. The pages already recognized stay
    // in the database, so coming back resumes rather than starts over.
    if (_running) _ocr.cancel();
    super.dispose();
  }

  Future<void> _run() async {
    for (int i = 0; i < widget.images.length; i++) {
      if (!mounted) return;
      try {
        final result = await _ocr.recognize(
          tableName: widget.tableName,
          image: widget.images[i],
        );
        if (!mounted) return;
        setState(() {
          _completed++;
          if (!result.isEmpty) _pages[i] = result;
        });
      } catch (e) {
        debugPrint('Could not read page ${i + 1}: $e');
        if (!mounted) return;
        setState(() => _failed++);
      }
    }
    if (mounted) setState(() => _running = false);
  }

  /// Every recognized page joined into one document, pages separated by a
  /// blank line. This is what copy and share hand over: a reader wants the
  /// document's text, not this screen's card layout.
  String get _allText {
    final ordered = _pages.keys.toList()..sort();
    return [for (final index in ordered) _pages[index]!.text].join('\n\n');
  }

  bool get _hasText => _pages.isNotEmpty;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _allText));
    if (!mounted) return;
    OSSnack.success(context, AppLocalizations.of(context)!.copied_to_clipboard);
  }

  Future<void> _share() async {
    await SharePlus.instance.share(
      ShareParams(text: _allText, subject: widget.documentName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    final l10n = AppLocalizations.of(context)!;
    final total = widget.images.length;
    final done = _completed + _failed;

    return Scaffold(
      backgroundColor: os.surface,
      appBar: AppBar(
        backgroundColor: os.surface,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.text_title,
                style: OSTypography.subtitle
                    .copyWith(color: os.onSurface, fontWeight: FontWeight.w800)),
            Text(
              _running ? l10n.pages_read(done, total) : widget.documentName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OSTypography.caption.copyWith(color: os.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_running)
              LinearProgressIndicator(
                minHeight: 3,
                value: total == 0 ? null : done / total,
                backgroundColor: os.surfaceVariant,
                color: os.accent,
              ),
            Expanded(child: _body(os, l10n)),
          ],
        ),
      ),
      bottomNavigationBar: _hasText ? _actions(os, l10n) : null,
    );
  }

  Widget _body(OSColors os, AppLocalizations l10n) {
    if (!_hasText) {
      // "Nothing yet" and "nothing at all" are different answers, and
      // telling a user mid-run that their scan is unreadable would be
      // wrong as often as it is right.
      return _running
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: OSSpace.md),
                  Text(l10n.reading_text,
                      style: OSTypography.body
                          .copyWith(color: os.onSurfaceVariant)),
                ],
              ),
            )
          : OSEmptyState(
              icon: Icons.text_fields_rounded,
              title: l10n.no_text_title,
              message: l10n.no_text_body,
            );
    }

    final ordered = _pages.keys.toList()..sort();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          OSSpace.md + 2, OSSpace.sm, OSSpace.md + 2, OSSpace.xl),
      itemCount: ordered.length,
      separatorBuilder: (_, __) => const SizedBox(height: OSSpace.md),
      itemBuilder: (context, index) => _PageText(
        // The page's own number in the document, not its position among
        // the pages that happened to yield text: a document whose second
        // page is a blank photo should still label the third page "3".
        pageNumber: ordered[index] + 1,
        text: _pages[ordered[index]]!.text,
      ),
    );
  }

  Widget _actions(OSColors os, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          OSSpace.md + 2, OSSpace.sm, OSSpace.md + 2, OSSpace.md),
      decoration: BoxDecoration(
        color: os.surface,
        border: Border(top: BorderSide(color: os.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OSButton(
                label: l10n.copy,
                icon: Icons.copy_rounded,
                kind: OSButtonKind.tonal,
                expand: true,
                onPressed: _copy,
              ),
            ),
            const SizedBox(width: OSSpace.sm),
            Expanded(
              child: OSButton(
                label: l10n.share_as_text,
                icon: Icons.ios_share_rounded,
                expand: true,
                onPressed: _share,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One page's text, on a card labelled with its page number.
class _PageText extends StatelessWidget {
  const _PageText({required this.pageNumber, required this.text});

  final int pageNumber;
  final String text;

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OSSpace.md),
      decoration: BoxDecoration(
        color: os.surfaceVariant,
        borderRadius: BorderRadius.circular(OSRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.page_number(pageNumber),
            style: OSTypography.caption.copyWith(
              color: os.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: OSSpace.xs),
          // Selectable so a user can lift one line out without taking the
          // whole document through the copy button.
          SelectableText(
            text,
            style: OSTypography.body.copyWith(color: os.onSurface, height: 1.45),
          ),
        ],
      ),
    );
  }
}
