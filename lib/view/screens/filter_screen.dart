import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openscan/core/image_filter/apply_filter.dart';
import 'package:openscan/core/image_filter/filters/document_filters.dart';
import 'package:openscan/core/image_filter/filters/filters.dart';
import 'package:openscan/core/models.dart';
import 'package:openscan/core/theme/appTheme.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/core/theme/os_typography.dart';
import 'package:openscan/l10n/app_localizations.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';
import 'package:openscan/view/Widgets/loading.dart';

/// Longest edge the large preview is rendered at. Filtering a
/// full-resolution capture just to look at it on a phone screen costs
/// seconds; this is indistinguishable and near-instant.
const int _previewMaxEdge = 1000;

/// Longest edge of the per-filter chips along the bottom.
const int _thumbnailMaxEdge = 160;

/// Localized label for a filter. [Filter.name] stays the stable,
/// non-localized id — it is the cache key and the value stored in the
/// database — so the two are resolved separately.
String filterLabel(BuildContext context, Filter filter) {
  final l10n = AppLocalizations.of(context)!;
  switch (filter.name) {
    case 'Auto':
      return l10n.filter_auto;
    case 'Lighten':
      return l10n.filter_lighten;
    case 'Grayscale':
      return l10n.filter_grayscale;
    case 'B&W':
      return l10n.filter_bw;
    case 'Whiteboard':
      return l10n.filter_whiteboard;
    default:
      return l10n.filter_original;
  }
}

/// Picks the colour mode for a page.
///
/// Every image shown here is derived from [ImageOS.filterSourcePath] — the
/// page's unfiltered version — so switching between modes always previews
/// the filter on its own, never stacked on the previous one.
class FilterScreen extends StatefulWidget {
  const FilterScreen({Key? key, required this.pageIndex}) : super(key: key);

  final int pageIndex;

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late final PageController _pageController;
  late int _pageIndex;
  late Filter _selected;

  /// Whether Done applies the chosen mode to every page rather than just
  /// this one. A visible switch rather than a hidden overflow item: it
  /// changes what the primary action does, so it has to be on screen.
  bool _applyToAll = false;

  /// Decoded, downscaled copies of each page's unfiltered source, keyed by
  /// `'<source path>|<max edge>'`. Filtering works off these rather than
  /// off the file, so a page is decoded once instead of once per chip.
  final Map<String, Uint8List> _sources = {};

  /// Insertion order of the preview-sized entries in [_sources]; see
  /// [_previewKeys] for why they are bounded.
  final List<String> _sourceKeys = [];

  /// Filtered results, keyed by [_key].
  final Map<String, Uint8List> _results = {};

  /// Insertion order of the large previews held in [_results], so the
  /// oldest can be dropped. Chips are tiny and kept indefinitely; previews
  /// are not, and a long document with every mode tried would otherwise
  /// accumulate megabytes of decoded JPEG.
  final List<String> _previewKeys = [];

  /// How many large previews to keep — enough for the current page's six
  /// modes, so flicking back and forth between two of them never recomputes.
  static const int _previewCacheSize = 8;

  final Set<String> _pending = {};

  /// Filtering runs one job at a time: each `compute` call spins up an
  /// isolate, and firing six chips plus a preview at once would leave the
  /// device thrashing instead of drawing sooner.
  Future<void> _queue = Future.value();

  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.pageIndex;
    _pageController = PageController(initialPage: widget.pageIndex);
    _selected = documentFilterByName(_imageAt(_pageIndex)?.filterName);
  }

  @override
  void dispose() {
    _disposed = true;
    _pageController.dispose();
    super.dispose();
  }

  ImageOS? _imageAt(int index) {
    final images = context.read<DirectoryCubit>().state.images;
    if (images == null || index < 0 || index >= images.length) return null;
    return images[index];
  }

  String _key(String sourcePath, Filter filter, int maxEdge) =>
      '$sourcePath|${filter.name}|$maxEdge';

  /// Schedules the work needed to show [filter] over [sourcePath] at
  /// [maxEdge], if it is not already cached or running.
  void _request(String sourcePath, Filter filter, int maxEdge) {
    final key = _key(sourcePath, filter, maxEdge);
    if (_results.containsKey(key) || _pending.contains(key)) return;
    _pending.add(key);

    _queue = _queue.then((_) async {
      if (_disposed) return;
      try {
        final source = await _source(sourcePath, maxEdge);
        final filtered = filter.name == defaultDocumentFilter.name
            ? source
            : await compute(filterBytesIsolateEntry, {
                'filter': filter.name,
                'bytes': source,
              });
        if (_disposed) return;
        setState(() => _cache(key, filtered, maxEdge));
      } catch (e) {
        debugPrint('Could not preview ${filter.name} for $sourcePath: $e');
      } finally {
        _pending.remove(key);
      }
    });
  }

  void _cache(String key, Uint8List bytes, int maxEdge) {
    _results[key] = bytes;
    if (maxEdge != _previewMaxEdge) return;
    _previewKeys.remove(key);
    _previewKeys.add(key);
    while (_previewKeys.length > _previewCacheSize) {
      _results.remove(_previewKeys.removeAt(0));
    }
  }

  /// The downscaled, unfiltered copy of [sourcePath], decoding it if this
  /// is the first request for that size.
  Future<Uint8List> _source(String sourcePath, int maxEdge) async {
    final key = '$sourcePath|$maxEdge';
    final cached = _sources[key];
    if (cached != null) return cached;

    final resized =
        await compute(applyFilterIsolateEntry, {
              'filter': defaultDocumentFilter.name,
              'src': sourcePath,
              'maxEdge': maxEdge,
            })
            as Uint8List;
    if (maxEdge == _previewMaxEdge) {
      // Preview-sized sources are the big ones; hold only a few pages'
      // worth so paging through a long document doesn't keep every one.
      _sourceKeys.remove(key);
      _sourceKeys.add(key);
      while (_sourceKeys.length > _previewCacheSize) {
        _sources.remove(_sourceKeys.removeAt(0));
      }
    }
    _sources[key] = resized;
    return resized;
  }

  Future<void> _confirm({required bool allPages}) async {
    final image = _imageAt(_pageIndex);
    if (image == null) return;

    final cubit = context.read<DirectoryCubit>();
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LoadingWidget(),
    );

    if (allPages) {
      await cubit.applyFilterToAllImages(filter: _selected);
    } else {
      await cubit.applyFilterToImage(imageOS: image, filter: _selected);
    }

    if (!mounted) return;
    navigator.pop(); // the loading dialog
    navigator.pop(); // this screen
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Fixed-dark chrome, like the preview: a full-bleed scan being colour
    // corrected is the wrong place to introduce a warm-white frame.
    return Scaffold(
      backgroundColor: OSColors.chromeBackground,
      appBar: AppBar(
        backgroundColor: OSColors.chromeBackground,
        foregroundColor: OSColors.chromeOnBackground,
        systemOverlayStyle: AppTheme.chromeOverlayStyle,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded,
              color: OSColors.chromeOnBackground),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          l10n.filters,
          style:
              OSTypography.subtitle.copyWith(color: OSColors.chromeOnBackground),
        ),
        actions: [
          TextButton(
            onPressed: () => _confirm(allPages: _applyToAll),
            child: Text(
              l10n.done,
              style: OSTypography.label.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: OSSpace.xs),
        ],
      ),
      body: BlocBuilder<DirectoryCubit, DirectoryState>(
        builder: (context, directoryState) {
          final images = directoryState.images ?? const <ImageOS>[];
          if (images.isEmpty) return const SizedBox.shrink();

          return PageView.builder(
            physics: const ClampingScrollPhysics(),
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _pageIndex = index;
                // Open each page on the filter it is already carrying.
                _selected = documentFilterByName(images[index].filterName);
              });
            },
            itemBuilder: (context, index) {
              final sourcePath = images[index].filterSourcePath;
              return Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(OSSpace.sm),
                      child: _FilteredImage(
                        bytes: _results[
                            _key(sourcePath, _selected, _previewMaxEdge)],
                        onMissing: () =>
                            _request(sourcePath, _selected, _previewMaxEdge),
                      ),
                    ),
                  ),
                  _applyToAllRow(images.length),
                  SizedBox(
                    height: 108,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: OSSpace.xs, vertical: OSSpace.xs),
                      itemCount: documentFiltersList.length,
                      itemBuilder: (context, filterIndex) {
                        final filter = documentFiltersList[filterIndex];
                        return _FilterChip(
                          label: filterLabel(context, filter),
                          selected: filter.name == _selected.name,
                          bytes: _results[
                              _key(sourcePath, filter, _thumbnailMaxEdge)],
                          onMissing: () =>
                              _request(sourcePath, filter, _thumbnailMaxEdge),
                          onTap: () => setState(() => _selected = filter),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _applyToAllRow(int pageCount) {
    if (pageCount < 2) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: OSSpace.md, vertical: OSSpace.xxs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Apply to all $pageCount pages',
              style: OSTypography.body
                  .copyWith(color: OSColors.chromeOnBackground),
            ),
          ),
          Switch(
            value: _applyToAll,
            activeThumbColor: Theme.of(context).colorScheme.onPrimary,
            activeTrackColor: accent,
            inactiveTrackColor: OSColors.chromeControl,
            onChanged: (value) => setState(() => _applyToAll = value),
          ),
        ],
      ),
    );
  }
}

/// Shows [bytes] once they exist, and asks for them exactly once per build
/// while they do not.
class _FilteredImage extends StatelessWidget {
  const _FilteredImage({required this.bytes, required this.onMissing});

  final Uint8List? bytes;
  final VoidCallback onMissing;

  @override
  Widget build(BuildContext context) {
    final bytes = this.bytes;
    if (bytes == null) {
      // Requesting during build is safe: the request is de-duplicated and
      // only ever calls setState from a later frame.
      onMissing();
      return Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(OSRadius.card),
      child: Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.bytes,
    required this.onMissing,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Uint8List? bytes;
  final VoidCallback onMissing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bytes = this.bytes;
    if (bytes == null) onMissing();

    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(horizontal: OSSpace.xxs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 62,
              width: 62,
              decoration: BoxDecoration(
                color: OSColors.chromeControl,
                border: Border.all(
                  color: selected ? accent : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(OSRadius.chip),
              ),
              clipBehavior: Clip.antiAlias,
              child: bytes == null
                  ? Center(
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: OSColors.chromeMuted,
                        ),
                      ),
                    )
                  : Image.memory(bytes, fit: BoxFit.cover),
            ),
            const SizedBox(height: OSSpace.xxs + 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OSTypography.caption.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color:
                    selected ? accent : OSColors.chromeMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
