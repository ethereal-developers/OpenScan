import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openscan/core/appRouter.dart';
import 'package:openscan/core/data/database_helper.dart';
import 'package:openscan/core/data/document_naming.dart';
import 'package:openscan/core/data/file_operations.dart';
import 'package:openscan/core/models.dart';
import 'package:openscan/core/settings/app_settings.dart';
import 'package:openscan/core/theme/appTheme.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/core/theme/os_typography.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';
import 'package:openscan/view/Widgets/os/os_components.dart';
import 'package:openscan/view/Widgets/renameDialog.dart';
import 'package:openscan/view/screens/demo_screen.dart';
import 'package:openscan/view/screens/view_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The app's home: every session starts by finding or checking a document,
/// so the library grid lands first and the camera is one prominent tap away
/// rather than being the root screen itself.
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper database = DatabaseHelper();
  final FileOperations fileOperations = FileOperations();
  final QuickActions quickActions = QuickActions();
  final TextEditingController _searchController = TextEditingController();

  List<DirectoryOS> _documents = [];
  bool _loading = true;
  String _query = '';

  /// Selection lives here rather than in a cubit: it is per-screen state
  /// that never outlives this route, and keying it by directory path keeps
  /// it correct across a refresh that rebuilds every [DirectoryOS].
  final Set<String> _selected = {};
  bool get _selectionMode => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _showDemoOnFirstLaunch();
    _refresh();

    quickActions.initialize((String shortcutType) {
      _startScan(shortcutType);
    });
    quickActions.setShortcutItems(<ShortcutItem>[
      ShortcutItem(
        type: 'Live Scan',
        localizedTitle: 'Scan',
        icon: 'normal_scan',
      ),
      ShortcutItem(
        type: 'Import from Gallery',
        localizedTitle: 'Import from Gallery',
        icon: 'gallery_action',
      ),
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _requestPermission() async {
    // A permission request can fail outright rather than be denied — the
    // platform side refuses a second request while one is still running,
    // for instance — and an unhandled failure here would take the library
    // down with it on launch. Asking is worth a try; not getting an answer
    // is not worth a crash.
    try {
      if (await Permission.storage.request().isGranted &&
          await Permission.camera.request().isGranted) {
        return true;
      }
      await Permission.storage.request();
      await Permission.camera.request();
    } catch (e) {
      debugPrint('Could not request permissions: $e');
    }
    return false;
  }

  Future<void> _showDemoOnFirstLaunch() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final visited = preferences.getBool('alreadyVisited') ?? false;
    await preferences.setBool('alreadyVisited', true);
    if (!visited && mounted) {
      Navigator.of(context).pushNamed(AppRouter.demoScreen);
    }
  }

  Future<void> _refresh() async {
    final data = await database.getMasterData();
    final seen = <String>{};
    final documents = <DirectoryOS>[];

    for (var directory in data) {
      if (!seen.add(directory['dir_path'])) continue;
      documents.add(
        DirectoryOS(
          dirName: directory['dir_name'],
          dirPath: directory['dir_path'],
          created: DateTime.parse(directory['created']),
          imageCount: directory['image_count'],
          firstImgPath: directory['first_img_path'],
          lastModified: DateTime.parse(directory['last_modified']),
          newName: directory['new_name'],
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _documents = documents;
      _loading = false;
      // A document deleted elsewhere must not stay selected.
      _selected.removeWhere(
          (path) => !documents.any((doc) => doc.dirPath == path));
    });
  }

  String _titleOf(DirectoryOS doc) => doc.newName ?? doc.dirName;

  /// The grid's contents: sorted by the user's chosen order, then narrowed
  /// by the search field.
  List<DirectoryOS> get _visibleDocuments {
    final documents = [..._documents];
    switch (AppSettings.instance.sort) {
      case LibrarySort.lastModified:
        documents.sort((a, b) => (b.lastModified ?? b.created)
            .compareTo(a.lastModified ?? a.created));
        break;
      case LibrarySort.created:
        documents.sort((a, b) => b.created.compareTo(a.created));
        break;
      case LibrarySort.name:
        documents.sort((a, b) =>
            _titleOf(a).toLowerCase().compareTo(_titleOf(b).toLowerCase()));
        break;
      case LibrarySort.pageCount:
        documents.sort((a, b) => b.imageCount.compareTo(a.imageCount));
        break;
    }

    if (_query.isEmpty) return documents;
    final query = _query.toLowerCase();
    return documents
        .where((doc) => _titleOf(doc).toLowerCase().contains(query))
        .toList();
  }

  // <========================= Navigation =========================>

  void _openDocument(DirectoryOS doc) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider<DirectoryCubit>(
          create: (context) => DirectoryCubit(
            dirName: doc.dirName,
            created: doc.created,
            dirPath: doc.dirPath,
            firstImgPath: doc.firstImgPath,
            imageCount: doc.imageCount,
            lastModified: doc.lastModified,
            newName: doc.newName,
            images: <ImageOS>[],
          )..getImageData(),
          lazy: false,
          child: ViewScreen(),
        ),
        settings: RouteSettings(name: AppRouter.viewScreen),
      ),
    ).whenComplete(_refresh);
  }

  /// Starts a capture session in a brand-new document and lands in
  /// Document detail when it finishes — never back in the library grid.
  /// The session is started by [ViewScreen] itself, which closes again if
  /// the user backs out of the camera without capturing anything, so a
  /// cancelled scan returns here rather than to an empty document.
  void _startScan(String scanType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider<DirectoryCubit>(
          create: (context) => DirectoryCubit()..createDirectory(),
          child: ViewScreen(initialScan: scanType),
        ),
        settings: RouteSettings(name: AppRouter.viewScreen),
      ),
    ).whenComplete(_refresh);
  }

  // <========================= Selection actions =========================>

  void _toggleSelection(DirectoryOS doc) {
    setState(() {
      if (!_selected.remove(doc.dirPath)) _selected.add(doc.dirPath);
    });
  }

  void _clearSelection() => setState(_selected.clear);

  void _selectAll() {
    setState(() {
      _selected.addAll(_visibleDocuments.map((doc) => doc.dirPath));
    });
  }

  List<DirectoryOS> get _selectedDocuments =>
      _documents.where((doc) => _selected.contains(doc.dirPath)).toList();

  Future<void> _deleteSelected() async {
    final documents = _selectedDocuments;
    Navigator.pop(context);

    for (final doc in documents) {
      final directory = Directory(doc.dirPath);
      if (directory.existsSync()) directory.deleteSync(recursive: true);
      await database.deleteDirectory(dirPath: doc.dirPath);
    }

    _clearSelection();
    await _refresh();
    if (!mounted) return;
    OSSnack.success(
      context,
      documents.length == 1
          ? 'Document deleted'
          : '${documents.length} documents deleted',
    );
  }

  /// Exports every selected document as its own PDF, so a multi-select
  /// export produces one file per document rather than merging unrelated
  /// scans into one.
  Future<void> _exportSelected() async {
    final documents = _selectedDocuments;
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ExportingDialog(),
    );

    int exported = 0;
    for (final doc in documents) {
      final rows = await database.getImageData(doc.dirName);
      final images = <ImageOS>[
        for (final row in rows)
          ImageOS(idx: row['idx'], imgPath: row['img_path']),
      ];
      if (images.isEmpty) continue;
      final path = await fileOperations.saveToDevice(
        fileName: exportFileName(_titleOf(doc)),
        images: images,
      );
      if (path != null) exported++;
    }

    if (!mounted) return;
    Navigator.pop(context); // the progress dialog
    _clearSelection();

    messenger.hideCurrentSnackBar();
    if (exported == documents.length) {
      OSSnack.success(context, 'Saved $exported to device');
    } else {
      OSSnack.error(context, "Couldn't export ${documents.length - exported}");
    }
  }

  // <========================= Sheets & menus =========================>

  void _openSortSheet() {
    OSSheet.show(
      context: context,
      title: 'Sort order',
      builder: (sheetContext) {
        final os = sheetContext.os;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final sort in LibrarySort.values)
              OSSheetAction(
                icon: switch (sort) {
                  LibrarySort.lastModified => Icons.history_rounded,
                  LibrarySort.created => Icons.event_rounded,
                  LibrarySort.name => Icons.sort_by_alpha_rounded,
                  LibrarySort.pageCount => Icons.filter_none_rounded,
                },
                label: sort.label,
                trailing: AppSettings.instance.sort == sort
                    ? Icon(Icons.check_rounded, size: 20, color: os.accent)
                    : null,
                onTap: () async {
                  await AppSettings.instance.setSort(sort);
                  if (mounted) Navigator.pop(sheetContext);
                  setState(() {});
                },
              ),
          ],
        );
      },
    );
  }

  void _openOverflow() {
    OSSheet.show(
      context: context,
      title: 'OpenScan',
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OSSheetAction(
            icon: Icons.settings_rounded,
            label: 'Settings',
            onTap: () {
              Navigator.pop(sheetContext);
              Navigator.pushNamed(context, AppRouter.settingsScreen)
                  .then((_) => setState(() {}));
            },
          ),
          OSSheetAction(
            icon: Icons.school_rounded,
            label: 'Tutorial',
            onTap: () {
              Navigator.pop(sheetContext);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DemoScreen(showSkip: false),
                ),
              );
            },
          ),
          OSSheetAction(
            icon: Icons.info_outline_rounded,
            label: 'About',
            onTap: () {
              Navigator.pop(sheetContext);
              Navigator.pushNamed(context, AppRouter.aboutScreen);
            },
          ),
        ],
      ),
    );
  }

  void _openDocumentMenu(DirectoryOS doc) {
    OSSheet.show(
      context: context,
      title: _titleOf(doc),
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OSSheetAction(
            icon: Icons.edit_rounded,
            label: 'Rename',
            onTap: () {
              Navigator.pop(sheetContext);
              showDialog(
                context: context,
                builder: (_) => RenameDialog(
                  onConfirm: (_) => _refresh(),
                  docTableName: doc.dirName,
                  fileName: _titleOf(doc),
                ),
              );
            },
          ),
          OSSheetAction(
            icon: Icons.select_all_rounded,
            label: 'Select',
            onTap: () {
              Navigator.pop(sheetContext);
              _toggleSelection(doc);
            },
          ),
          OSSheetAction(
            icon: Icons.delete_rounded,
            label: 'Delete',
            destructive: true,
            onTap: () {
              Navigator.pop(sheetContext);
              _selected
                ..clear()
                ..add(doc.dirPath);
              _confirmDelete();
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete() {
    final count = _selected.length;
    showDialog(
      context: context,
      builder: (_) => OSDialog(
        title: count == 1 ? 'Delete document?' : 'Delete $count documents?',
        message: "This can't be undone.",
        confirmLabel: 'Delete',
        destructive: true,
        onConfirm: _deleteSelected,
      ),
    ).then((_) {
      // Backing out of the dialog must not leave a document silently
      // selected from the long-press menu path above.
      if (mounted && _selected.length == 1) _clearSelection();
    });
  }

  // <========================= Build =========================>

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    final documents = _visibleDocuments;

    return PopScope(
      canPop: !_selectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSelection();
      },
      child: Scaffold(
        backgroundColor: os.surface,
        appBar: _selectionMode
            ? _selectionAppBar(os)
            : _libraryAppBar(os),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: os.accent,
            backgroundColor: os.surfaceContainer,
            child: _body(os, documents),
          ),
        ),
        bottomNavigationBar: _selectionMode ? _selectionBar(os) : null,
        floatingActionButton: _selectionMode
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _startScan('Live Scan'),
                icon: const Icon(Icons.camera_alt_rounded, size: 20),
                label: const Text('Scan'),
                backgroundColor: os.accent,
                foregroundColor: os.onAccent,
              ),
      ),
    );
  }

  PreferredSizeWidget _libraryAppBar(OSColors os) {
    return AppBar(
      backgroundColor: os.surface,
      titleSpacing: OSSpace.md + 2,
      title: Text('Library',
          style: OSTypography.display.copyWith(fontSize: 26, height: 1.2)),
      actions: [
        IconButton(
          tooltip: 'Sort',
          icon: const Icon(Icons.sort_rounded),
          onPressed: _openSortSheet,
        ),
        IconButton(
          tooltip: 'Import from gallery',
          icon: const Icon(Icons.add_photo_alternate_outlined),
          onPressed: () => _startScan('Import from Gallery'),
        ),
        IconButton(
          tooltip: 'More',
          icon: const Icon(Icons.more_vert_rounded),
          onPressed: _openOverflow,
        ),
        const SizedBox(width: OSSpace.xxs),
      ],
    );
  }

  /// Selection mode swaps in an inverted bar rather than tinting the
  /// existing one, so "you are selecting" is legible at a glance.
  PreferredSizeWidget _selectionAppBar(OSColors os) {
    return AppBar(
      backgroundColor: os.onSurface,
      foregroundColor: os.surface,
      systemOverlayStyle: AppTheme.invertedOverlayStyle(
          os, Theme.of(context).brightness),
      leading: IconButton(
        icon: Icon(Icons.close_rounded, color: os.surface),
        onPressed: _clearSelection,
      ),
      title: Text('${_selected.length} selected',
          style: OSTypography.subtitle.copyWith(color: os.surface)),
      actions: [
        TextButton(
          onPressed: _selectAll,
          child: Text('Select all',
              style: OSTypography.label.copyWith(
                  fontWeight: FontWeight.w700, color: os.accent)),
        ),
        const SizedBox(width: OSSpace.xs),
      ],
    );
  }

  Widget _selectionBar(OSColors os) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            OSSpace.md + 2, OSSpace.xs, OSSpace.md + 2, OSSpace.md),
        child: Row(
          children: [
            Expanded(
              child: OSButton(
                label: 'Export',
                kind: OSButtonKind.tonal,
                expand: true,
                onPressed: _exportSelected,
              ),
            ),
            const SizedBox(width: OSSpace.sm),
            Expanded(
              child: OSButton(
                label: 'Delete',
                kind: OSButtonKind.danger,
                expand: true,
                onPressed: _confirmDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(OSColors os, List<DirectoryOS> documents) {
    if (_loading) return _skeleton(os);

    if (_documents.isEmpty) {
      return _scrollable(
        OSEmptyState(
          icon: Icons.description_outlined,
          title: 'No documents yet',
          message:
              'Scan your first page — it takes about two seconds and stays '
              'only on this device.',
          action: OSButton(
            label: 'Start scanning',
            onPressed: () => _startScan('Live Scan'),
          ),
        ),
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (!_selectionMode)
          SliverToBoxAdapter(child: _searchField(os)),
        if (documents.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: OSEmptyState(
              icon: Icons.search_off_rounded,
              title: 'No results for "$_query"',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                OSSpace.md + 2, 0, OSSpace.md + 2, 96),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: OSSpace.sm,
                mainAxisSpacing: OSSpace.md,
                childAspectRatio: 0.82,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _DocumentCard(
                  document: documents[index],
                  title: _titleOf(documents[index]),
                  selected: _selected.contains(documents[index].dirPath),
                  selectionMode: _selectionMode,
                  onTap: () => _selectionMode
                      ? _toggleSelection(documents[index])
                      : _openDocument(documents[index]),
                  onLongPress: () => _selectionMode
                      ? _toggleSelection(documents[index])
                      : _openDocumentMenu(documents[index]),
                ),
                childCount: documents.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _searchField(OSColors os) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          OSSpace.md + 2, 0, OSSpace.md + 2, OSSpace.sm),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value.trim()),
        style: OSTypography.body.copyWith(color: os.onSurface),
        decoration: InputDecoration(
          hintText: 'Search documents',
          prefixIcon:
              Icon(Icons.search_rounded, size: 20, color: os.onSurfaceVariant),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 40),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
        ),
      ),
    );
  }

  Widget _skeleton(OSColors os) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: OSSpace.sm),
              child: Text('Refreshing…',
                  style:
                      OSTypography.caption.copyWith(color: os.onSurfaceVariant)),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: OSSpace.md + 2),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: OSSpace.sm,
              mainAxisSpacing: OSSpace.md,
              childAspectRatio: 0.82,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => Container(
                decoration: BoxDecoration(
                  color: os.surfaceContainer,
                  borderRadius: BorderRadius.circular(OSRadius.card),
                ),
              ),
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _scrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: child,
        ),
      ),
    );
  }
}

/// One library cell: page thumbnail, title, and "date · N pages".
class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.title,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  final DirectoryOS document;
  final String title;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get _subtitle {
    final date = document.lastModified ?? document.created;
    final pages =
        document.imageCount == 1 ? '1 page' : '${document.imageCount} pages';
    return '${_months[date.month - 1]} ${date.day} · $pages';
  }

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    final path = document.firstImgPath;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: OSMotion.selection,
              curve: OSMotion.standardCurve,
              width: double.infinity,
              decoration: BoxDecoration(
                color: os.surfaceVariant,
                borderRadius: BorderRadius.circular(OSRadius.card),
                border: Border.all(
                  color: selected ? os.accent : os.outline,
                  width: selected ? 2.5 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (path != null && path.isNotEmpty && File(path).existsSync())
                    Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, __, ___) => _placeholder(os),
                    )
                  else
                    _placeholder(os),
                  if (selectionMode)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: AnimatedScale(
                        scale: selected ? 1 : 0.7,
                        duration: OSMotion.selection,
                        child: Container(
                          height: 20,
                          width: 20,
                          decoration: BoxDecoration(
                            color: selected ? os.accent : os.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: os.outline),
                          ),
                          child: selected
                              ? Icon(Icons.check_rounded,
                                  size: 14, color: os.onAccent)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: OSSpace.xs),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OSTypography.label
                .copyWith(fontWeight: FontWeight.w700, color: os.onSurface),
          ),
          Text(
            _subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OSTypography.caption.copyWith(color: os.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(OSColors os) => ColoredBox(
        color: os.surfaceVariant,
        child: Icon(Icons.description_outlined, color: os.outline),
      );
}

/// Barrier-blocking progress used while a multi-document export runs.
class _ExportingDialog extends StatelessWidget {
  const _ExportingDialog();

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    return Dialog(
      backgroundColor: os.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OSRadius.sheet),
      ),
      child: Padding(
        padding: const EdgeInsets.all(OSSpace.xl),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: os.accent),
            ),
            const SizedBox(width: OSSpace.md),
            Text('Exporting…',
                style: OSTypography.body.copyWith(color: os.onSurface)),
          ],
        ),
      ),
    );
  }
}
