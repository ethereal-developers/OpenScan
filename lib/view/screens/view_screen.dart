import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openscan/core/appRouter.dart';
import 'package:openscan/core/models.dart';
import 'package:openscan/core/theme/appTheme.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/core/theme/os_typography.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';
import 'package:openscan/view/Widgets/os/os_components.dart';
import 'package:openscan/view/Widgets/renameDialog.dart';
import 'package:openscan/view/Widgets/view/export_bottomsheet.dart';
import 'package:openscan/view/screens/preview_screen.dart';
import 'package:reorderables/reorderables.dart';

/// Document detail: where every scan session lands.
///
/// Pages are reorderable cards, the title renames in place, and the two
/// things you actually do next — add more pages, export — are the only
/// persistent buttons.
class ViewScreen extends StatefulWidget {
  /// The scan type to start as soon as this screen opens, for a document
  /// created by a scan rather than opened from the library. Null for an
  /// existing document.
  final String? initialScan;

  ViewScreen({this.initialScan});

  @override
  _ViewScreenState createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> {
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    final scanType = widget.initialScan;
    if (scanType != null) {
      // After the first frame: createImage pushes the camera route, and a
      // route cannot be pushed from inside another route's build.
      WidgetsBinding.instance.addPostFrameCallback((_) => _startSession(
            fromGallery: scanType == 'Import from Gallery',
            liveScan: scanType == 'Live Scan',
          ));
    }
  }

  /// Runs a capture session and, if it ends with the document still empty,
  /// closes this screen: a document nobody put a page in is not worth
  /// landing on — backing out of the camera should land back where the
  /// scan was started from.
  Future<void> _startSession({
    bool fromGallery = false,
    bool liveScan = false,
  }) async {
    final cubit = BlocProvider.of<DirectoryCubit>(context);
    final navigator = Navigator.of(context);
    await cubit.createImage(
      context,
      fromGallery: fromGallery,
      liveScan: liveScan,
    );
    if (!mounted) return;
    if ((cubit.state.images ?? const []).isEmpty && navigator.canPop()) {
      navigator.pop();
    }
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  int _selectedCount(DirectoryState state) =>
      state.images?.where((image) => image.selected).length ?? 0;

  void _exitSelection() {
    BlocProvider.of<DirectoryCubit>(context).resetSelection();
    setState(() => _selectionMode = false);
  }

  void _addPages({bool fromGallery = false}) {
    _startSession(fromGallery: fromGallery, liveScan: !fromGallery);
  }

  void _rename(DirectoryState state) {
    showDialog(
      context: context,
      builder: (_) => RenameDialog(
        onConfirm: (newName) =>
            BlocProvider.of<DirectoryCubit>(context).renameDocument(newName),
        docTableName: state.dirName!,
        fileName: state.newName ?? state.dirName!,
      ),
    );
  }

  void _openExport({required bool imagesSelected}) {
    OSSheet.show(
      context: context,
      builder: (_) => BlocProvider<DirectoryCubit>.value(
        value: BlocProvider.of<DirectoryCubit>(context),
        child: ExportSheet(imagesSelected: imagesSelected),
      ),
    );
  }

  void _confirmDeleteSelected(DirectoryState state) {
    final count = _selectedCount(state);
    showDialog(
      context: context,
      builder: (_) => OSDialog(
        title: count == 1 ? 'Delete page?' : 'Delete $count pages?',
        message: "This can't be undone.",
        confirmLabel: 'Delete',
        destructive: true,
        onConfirm: () {
          final returnHome = BlocProvider.of<DirectoryCubit>(context)
              .deleteSelectedImages(context);
          Navigator.pop(context); // the dialog
          if (returnHome) {
            Navigator.popUntil(
                context, ModalRoute.withName(AppRouter.homeScreen));
          } else {
            setState(() => _selectionMode = false);
          }
        },
      ),
    );
  }

  void _openOverflow(DirectoryState state) {
    OSSheet.show(
      context: context,
      title: state.newName ?? state.dirName ?? '',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OSSheetAction(
            icon: Icons.edit_rounded,
            label: 'Rename',
            onTap: () {
              Navigator.pop(sheetContext);
              _rename(state);
            },
          ),
          OSSheetAction(
            icon: Icons.checklist_rounded,
            label: 'Select pages',
            onTap: () {
              Navigator.pop(sheetContext);
              setState(() => _selectionMode = true);
            },
          ),
          OSSheetAction(
            icon: Icons.add_photo_alternate_outlined,
            label: 'Import from gallery',
            onTap: () {
              Navigator.pop(sheetContext);
              _addPages(fromGallery: true);
            },
          ),
          OSSheetAction(
            icon: Icons.ios_share_rounded,
            label: 'Export',
            onTap: () {
              Navigator.pop(sheetContext);
              _openExport(imagesSelected: false);
            },
          ),
          OSSheetAction(
            icon: Icons.delete_rounded,
            label: 'Delete document',
            destructive: true,
            onTap: () {
              Navigator.pop(sheetContext);
              showDialog(
                context: context,
                builder: (_) => OSDialog(
                  title: 'Delete document?',
                  message: "Every page goes with it. This can't be undone.",
                  confirmLabel: 'Delete',
                  destructive: true,
                  onConfirm: () {
                    BlocProvider.of<DirectoryCubit>(context)
                        .deleteSelectedImages(context, deleteAll: true);
                    Navigator.popUntil(
                        context, ModalRoute.withName(AppRouter.homeScreen));
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final os = context.os;

    return BlocBuilder<DirectoryCubit, DirectoryState>(
      builder: (context, state) {
        final images = state.images ?? const <ImageOS>[];
        final selectedCount = _selectedCount(state);

        return PopScope(
          canPop: !_selectionMode,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _exitSelection();
          },
          child: Scaffold(
            backgroundColor: os.surface,
            appBar: _selectionMode
                ? _selectionAppBar(os, selectedCount, state)
                : _documentAppBar(os, state),
            body: SafeArea(
              top: false,
              child: images.isEmpty && state.pendingPages.isEmpty
                  ? OSEmptyState(
                      icon: Icons.add_rounded,
                      title: 'This document has no pages',
                      message: 'Named after your first page — rename anytime '
                          'by tapping the title.',
                    )
                  : _pageGrid(os, state, images),
            ),
            bottomNavigationBar: _bottomBar(os, state, selectedCount),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _documentAppBar(OSColors os, DirectoryState state) {
    final title = state.newName ?? state.dirName ?? '';
    final date = state.lastModified ?? state.created;
    final pages = state.imageCount == 1 ? '1 page' : '${state.imageCount} pages';
    final subtitle = state.imageCount > 1
        ? '$pages · hold a page to reorder'
        : date == null
            ? pages
            : '$pages · ${_months[date.month - 1]} ${date.day}';

    return AppBar(
      backgroundColor: os.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context, true),
      ),
      titleSpacing: 0,
      // The title carries its own subtitle rather than using a
      // bottom: widget, so the dashed "tap to rename" affordance and the
      // page count stay visually attached to each other.
      title: GestureDetector(
        onTap: () => _rename(state),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OSTypography.subtitle.copyWith(
                      color: os.onSurface,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.dashed,
                      decorationColor: os.outline,
                    ),
                  ),
                ),
                const SizedBox(width: OSSpace.xs),
                Icon(Icons.edit_rounded, size: 14, color: os.onSurfaceVariant),
              ],
            ),
            Text(subtitle,
                style:
                    OSTypography.caption.copyWith(color: os.onSurfaceVariant)),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: () => _openOverflow(state),
        ),
        const SizedBox(width: OSSpace.xxs),
      ],
    );
  }

  PreferredSizeWidget _selectionAppBar(
      OSColors os, int count, DirectoryState state) {
    return AppBar(
      backgroundColor: os.onSurface,
      foregroundColor: os.surface,
      systemOverlayStyle: AppTheme.invertedOverlayStyle(
          os, Theme.of(context).brightness),
      leading: IconButton(
        icon: Icon(Icons.close_rounded, color: os.surface),
        onPressed: _exitSelection,
      ),
      title: Text('$count selected',
          style: OSTypography.subtitle.copyWith(color: os.surface)),
      actions: [
        IconButton(
          tooltip: 'Select all',
          icon: Icon(Icons.select_all_rounded, color: os.surface),
          onPressed: () =>
              BlocProvider.of<DirectoryCubit>(context).selectAllImages(),
        ),
        IconButton(
          tooltip: 'Delete',
          icon: Icon(Icons.delete_rounded, color: os.accent),
          onPressed: count == 0 ? null : () => _confirmDeleteSelected(state),
        ),
        const SizedBox(width: OSSpace.xxs),
      ],
    );
  }

  Widget _pageGrid(OSColors os, DirectoryState state, List<ImageOS> images) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = OSSpace.xs + 2;
        const padding = OSSpace.md + 2;
        final tileWidth =
            (constraints.maxWidth - padding * 2 - spacing * 2) / 3;

        final pendingTiles = <Widget>[
          for (int i = 0; i < state.pendingPages.length; i++)
            _PendingTile(
              key: ValueKey('pending-${state.pendingPages[i]}'),
              path: state.pendingPages[i],
              index: images.length + i + 1,
              width: tileWidth,
            ),
        ];

        final tiles = <Widget>[
          for (final image in images)
            _PageTile(
              key: ValueKey(image.imgPath),
              image: image,
              width: tileWidth,
              selectionMode: _selectionMode,
              onTap: () {
                if (_selectionMode) {
                  BlocProvider.of<DirectoryCubit>(context).selectImage(image);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider<DirectoryCubit>.value(
                        value: BlocProvider.of<DirectoryCubit>(context),
                        child: PreviewScreen(initialIndex: image.idx! - 1),
                      ),
                    ),
                  );
                }
              },
            ),
        ];

        // Pending pages sit outside the reorderable set: they have no
        // database row yet, so there is no index for a drag to rewrite.
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(padding, OSSpace.xs, padding, 96),
          child: Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              if (_selectionMode || pendingTiles.isNotEmpty)
                ...tiles
              else
                ReorderableWrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  needsLongPressDraggable: true,
                  children: tiles,
                  onReorder: (oldIndex, newIndex) {
                    BlocProvider.of<DirectoryCubit>(context)
                        .updateImageIndex(oldIndex, newIndex);
                  },
                ),
              ...pendingTiles,
            ],
          ),
        );
      },
    );
  }

  Widget? _bottomBar(OSColors os, DirectoryState state, int selectedCount) {
    if ((state.images ?? const []).isEmpty && state.pendingPages.isEmpty) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              OSSpace.md + 2, OSSpace.xs, OSSpace.md + 2, OSSpace.md),
          child: OSButton(
            label: 'Continue scanning',
            icon: Icons.add_rounded,
            expand: true,
            onPressed: _addPages,
          ),
        ),
      );
    }

    if (_selectionMode) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              OSSpace.md + 2, OSSpace.xs, OSSpace.md + 2, OSSpace.md),
          child: OSButton(
            label: selectedCount == 0
                ? 'Export selected'
                : 'Export $selectedCount selected',
            expand: true,
            onPressed: selectedCount == 0
                ? null
                : () => _openExport(imagesSelected: true),
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            OSSpace.md + 2, OSSpace.xs, OSSpace.md + 2, OSSpace.md),
        child: Row(
          children: [
            Expanded(
              child: OSButton(
                label: 'Add pages',
                icon: Icons.add_rounded,
                kind: OSButtonKind.tonal,
                expand: true,
                onPressed: _addPages,
              ),
            ),
            const SizedBox(width: OSSpace.sm),
            Expanded(
              child: OSButton(
                label: 'Export',
                expand: true,
                onPressed: () => _openExport(imagesSelected: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One page in the document grid.
class _PageTile extends StatelessWidget {
  const _PageTile({
    Key? key,
    required this.image,
    required this.width,
    required this.selectionMode,
    required this.onTap,
  }) : super(key: key);

  final ImageOS image;
  final double width;
  final bool selectionMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    final selected = image.selected;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: width * 4 / 3,
        child: AnimatedContainer(
          duration: OSMotion.selection,
          decoration: BoxDecoration(
            color: os.surfaceVariant,
            borderRadius: BorderRadius.circular(OSRadius.chip + 1),
            border: Border.all(
              color: selected ? os.accent : os.outline,
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'hero-image-${image.idx}',
                child: Image.file(
                  File(image.imgPath),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.broken_image_outlined,
                    color: os.outline,
                  ),
                ),
              ),
              if (selectionMode)
                Positioned(
                  top: 4,
                  right: 4,
                  child: AnimatedScale(
                    scale: selected ? 1 : 0.7,
                    duration: OSMotion.selection,
                    child: Container(
                      height: 17,
                      width: 17,
                      decoration: BoxDecoration(
                        color: selected ? os.accent : os.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: os.outline),
                      ),
                      child: selected
                          ? Icon(Icons.check_rounded,
                              size: 12, color: os.onAccent)
                          : null,
                    ),
                  ),
                )
              else
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: os.overlayChrome,
                      borderRadius: BorderRadius.circular(OSRadius.chip),
                    ),
                    child: Text('${image.idx}',
                        style: OSTypography.caption
                            .copyWith(color: Colors.white)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A page that has been captured but not yet written into the document.
///
/// Shows the capture itself, dimmed, with a progress line across the
/// bottom: the scan is visibly there and visibly still landing, which is
/// the honest version of a grid that would otherwise sit empty for a
/// second or two per page.
class _PendingTile extends StatelessWidget {
  const _PendingTile({
    Key? key,
    required this.path,
    required this.index,
    required this.width,
  }) : super(key: key);

  final String path;
  final int index;
  final double width;

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    return SizedBox(
      width: width,
      height: width * 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: os.surfaceVariant,
          borderRadius: BorderRadius.circular(OSRadius.chip + 1),
          border: Border.all(color: os.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: 0.45,
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                // Decoded straight to tile size rather than at capture
                // resolution: this is a thumbnail of a photo that is being
                // re-encoded on another isolate right now, and the two
                // should not be competing for the same CPU.
                cacheWidth: (width * MediaQuery.of(context).devicePixelRatio)
                    .round(),
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: os.outline,
                valueColor: AlwaysStoppedAnimation(os.accent),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: os.overlayChrome,
                  borderRadius: BorderRadius.circular(OSRadius.chip),
                ),
                child: Text('$index',
                    style: OSTypography.caption.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
