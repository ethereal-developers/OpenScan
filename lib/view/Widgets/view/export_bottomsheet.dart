import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:openscan/core/data/file_operations.dart';
import 'package:openscan/core/models.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/core/theme/os_typography.dart';
import 'package:openscan/logic/cubit/directory_cubit.dart';
import 'package:openscan/view/Widgets/os/os_components.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';

enum ExportFormat { pdf, jpg, png }

enum ExportQuality { low, medium, high, extreme }

enum ExportPageSize { a4, letter, legal }

enum _Stage { idle, exporting, success, failure }

extension on ExportFormat {
  String get label => name.toUpperCase();
  String get extension => name;
}

extension on ExportQuality {
  String get label {
    switch (this) {
      case ExportQuality.low:
        return 'Low';
      case ExportQuality.medium:
        return 'Medium';
      case ExportQuality.high:
        return 'High';
      case ExportQuality.extreme:
        return 'Extreme';
    }
  }

  /// JPEG quality the page is re-encoded at.
  int get encodeQuality {
    switch (this) {
      case ExportQuality.low:
        return 55;
      case ExportQuality.medium:
        return 70;
      case ExportQuality.high:
        return 85;
      case ExportQuality.extreme:
        return 100;
    }
  }

  /// Rough multiplier against the pages' current on-disk size, used only
  /// for the "~N MB" hint next to each option.
  double get sizeFactor {
    switch (this) {
      case ExportQuality.low:
        return 0.25;
      case ExportQuality.medium:
        return 0.5;
      case ExportQuality.high:
        return 1.0;
      case ExportQuality.extreme:
        return 1.6;
    }
  }

  /// [FileOperations.saveToDevice]'s three-step quality scale.
  int get legacyQuality {
    switch (this) {
      case ExportQuality.low:
        return 1;
      case ExportQuality.medium:
        return 2;
      default:
        return 3;
    }
  }
}

extension on ExportPageSize {
  String get label {
    switch (this) {
      case ExportPageSize.a4:
        return 'A4';
      case ExportPageSize.letter:
        return 'Letter';
      case ExportPageSize.legal:
        return 'Legal';
    }
  }

  PdfPageFormat get format {
    switch (this) {
      case ExportPageSize.a4:
        return PdfPageFormat.a4;
      case ExportPageSize.letter:
        return PdfPageFormat.letter;
      case ExportPageSize.legal:
        return PdfPageFormat.legal;
    }
  }
}

/// The one export surface: format, quality, page size and destination all
/// in a single sheet, which then becomes its own progress, success and
/// failure states rather than handing off to a toast.
class ExportSheet extends StatefulWidget {
  const ExportSheet({Key? key, this.imagesSelected = false}) : super(key: key);

  /// Export only the pages the user ticked, rather than the whole document.
  final bool imagesSelected;

  @override
  State<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<ExportSheet> {
  final FileOperations fileOperations = FileOperations();

  ExportFormat _format = ExportFormat.pdf;
  ExportQuality _quality = ExportQuality.high;
  ExportPageSize _pageSize = ExportPageSize.a4;

  _Stage _stage = _Stage.idle;
  int _progressPage = 0;
  String? _resultPath;
  int _resultCount = 0;
  String? _resultSize;
  String? _errorMessage;

  List<ImageOS> _pages(DirectoryState state) {
    final images = state.images ?? const <ImageOS>[];
    if (!widget.imagesSelected) return images;
    final selected = images.where((image) => image.selected).toList();
    return selected.isEmpty ? images : selected;
  }

  String _documentName(DirectoryState state) =>
      state.newName ?? state.dirName ?? 'OpenScan';

  /// A filename safe on every filesystem the export can land on, suffixed
  /// with the date so repeated exports of one document don't collide.
  String _fileName(DirectoryState state) {
    final cleaned = _documentName(state)
        .replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final date = DateTime.now();
    final stamp = '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    return '${cleaned.isEmpty ? 'OpenScan' : cleaned}_$stamp';
  }

  int _sourceBytes(List<ImageOS> pages) {
    var total = 0;
    for (final page in pages) {
      final file = File(page.imgPath);
      if (file.existsSync()) total += file.lengthSync();
    }
    return total;
  }

  static String _formatBytes(num bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  // <========================= Running the export =========================>

  Future<void> _run({required bool share}) async {
    final state = context.read<DirectoryCubit>().state;
    final pages = _pages(state);
    if (pages.isEmpty) {
      setState(() {
        _stage = _Stage.failure;
        _errorMessage = 'There are no pages to export.';
      });
      return;
    }

    setState(() {
      _stage = _Stage.exporting;
      _progressPage = 0;
    });

    try {
      final name = _fileName(state);
      List<String> written;

      if (_format == ExportFormat.pdf) {
        // The PDF is produced in one pass off the UI isolate, so the
        // progress line counts pages handed to it rather than pretending
        // to track encoding.
        setState(() => _progressPage = pages.length);
        final path = share
            ? await fileOperations.saveToAppDirectory(
                context: context,
                fileName: name,
                images: pages,
                pageFormat: _pageSize.format,
                imagesSelected: false,
              )
            : await fileOperations.saveToDevice(
                context: context,
                fileName: name,
                images: pages,
                pageFormat: _pageSize.format,
                quality: _quality.legacyQuality,
              );
        if (path == null) throw StateError('PDF could not be written');
        written = [path];
      } else {
        final directory = share
            ? await fileOperations.exportDirectory()
            : await fileOperations.exportDirectory(context: context);
        written = await fileOperations.exportImages(
          images: pages,
          directory: directory,
          baseName: name,
          format: _format.extension,
          quality: _quality.encodeQuality,
        );
      }

      final bytes = written.fold<int>(
          0, (sum, path) => sum + (File(path).existsSync() ? File(path).lengthSync() : 0));

      if (!mounted) return;
      setState(() {
        _stage = _Stage.success;
        _resultPath = written.first;
        _resultCount = written.length;
        _resultSize = _formatBytes(bytes);
      });

      if (share) {
        await SharePlus.instance.share(
          ShareParams(
            files: [for (final path in written) XFile(path)],
            subject: _documentName(state),
          ),
        );
      }
    } catch (e) {
      debugPrint('Export failed: $e');
      if (!mounted) return;
      setState(() {
        _stage = _Stage.failure;
        _errorMessage = e is FileSystemException
            ? 'Not enough storage space on this device.'
            : "Something went wrong while exporting.";
      });
    }
  }

  // <========================= Build =========================>

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectoryCubit, DirectoryState>(
      builder: (context, state) {
        switch (_stage) {
          case _Stage.idle:
            return _idle(state);
          case _Stage.exporting:
            return _exporting(state);
          case _Stage.success:
            return _success();
          case _Stage.failure:
            return _failure();
        }
      },
    );
  }

  Widget _idle(DirectoryState state) {
    final os = context.os;
    final pages = _pages(state);
    final estimate = _sourceBytes(pages);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Export · ${_documentName(state)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OSTypography.subtitle.copyWith(color: os.onSurface)),
        const SizedBox(height: OSSpace.md),
        OSSegmented<ExportFormat>(
          values: ExportFormat.values,
          labels: [for (final f in ExportFormat.values) f.label],
          selected: _format,
          onChanged: (value) => setState(() => _format = value),
        ),
        const SizedBox(height: OSSpace.md),
        Text('QUALITY',
            style: OSTypography.caption.copyWith(
              color: os.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            )),
        const SizedBox(height: OSSpace.xs),
        Row(
          children: [
            for (final quality in ExportQuality.values) ...[
              Expanded(
                child: _QualityOption(
                  label: quality.label,
                  // PNG is lossless, so its size does not move with the
                  // quality control and the hint would be a lie.
                  hint: _format == ExportFormat.png
                      ? '—'
                      : '~${_formatBytes(estimate * quality.sizeFactor)}',
                  selected: _quality == quality,
                  onTap: () => setState(() => _quality = quality),
                ),
              ),
              if (quality != ExportQuality.values.last)
                const SizedBox(width: OSSpace.xs),
            ],
          ],
        ),
        const SizedBox(height: OSSpace.sm),
        if (_format == ExportFormat.pdf)
          _MetaRow(
            label: 'Page size',
            value: _pageSize.label,
            onTap: () => setState(() {
              _pageSize = ExportPageSize.values[
                  (_pageSize.index + 1) % ExportPageSize.values.length];
            }),
          ),
        _MetaRow(
          label: widget.imagesSelected ? 'Selected pages' : 'All pages',
          value: pages.length == 1 ? '1 page' : '${pages.length} pages',
        ),
        const SizedBox(height: OSSpace.sm),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: OSSpace.sm, vertical: OSSpace.xs + 2),
          decoration: BoxDecoration(
            color: os.surfaceVariant,
            borderRadius: BorderRadius.circular(OSRadius.chip),
          ),
          child: Text(
            '${_fileName(state)}.${_format.extension}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OSTypography.caption.copyWith(color: os.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: OSSpace.md),
        Row(
          children: [
            Expanded(
              child: OSButton(
                label: 'Save',
                kind: OSButtonKind.tonal,
                expand: true,
                onPressed: () => _run(share: false),
              ),
            ),
            const SizedBox(width: OSSpace.sm),
            Expanded(
              child: OSButton(
                label: 'Share',
                expand: true,
                onPressed: () => _run(share: true),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _exporting(DirectoryState state) {
    final os = context.os;
    final total = _pages(state).length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Exporting…',
            style: OSTypography.subtitle.copyWith(color: os.onSurface)),
        const SizedBox(height: OSSpace.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: total == 0 ? null : _progressPage / total,
            backgroundColor: os.surfaceVariant,
            color: os.accent,
          ),
        ),
        const SizedBox(height: OSSpace.xs),
        Text('Page ${_progressPage.clamp(1, total)} of $total',
            style: OSTypography.caption.copyWith(color: os.onSurfaceVariant)),
      ],
    );
  }

  Widget _success() {
    final os = context.os;
    final path = _resultPath;
    final name = path?.split('/').last ?? '';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 28,
              width: 28,
              decoration:
                  BoxDecoration(color: os.success, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  size: 18, color: Colors.white),
            ),
            const SizedBox(width: OSSpace.sm),
            Text('Exported',
                style: OSTypography.subtitle.copyWith(color: os.onSurface)),
          ],
        ),
        const SizedBox(height: OSSpace.xs),
        Text(
          [
            // An image export writes one file per page; naming only the
            // first would under-report what actually landed on disk.
            _resultCount > 1 ? '$name + ${_resultCount - 1} more' : name,
            if (_resultSize != null) _resultSize!,
          ].join(' · '),
          maxLines: 2,
          style: OSTypography.caption.copyWith(color: os.onSurfaceVariant),
        ),
        const SizedBox(height: OSSpace.md),
        Row(
          children: [
            Expanded(
              child: OSButton(
                label: 'Open',
                kind: OSButtonKind.tonal,
                expand: true,
                onPressed: path == null ? null : () => OpenFilex.open(path),
              ),
            ),
            const SizedBox(width: OSSpace.sm),
            Expanded(
              child: OSButton(
                label: 'Done',
                expand: true,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _failure() {
    final os = context.os;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 28,
              width: 28,
              decoration:
                  BoxDecoration(color: os.danger, shape: BoxShape.circle),
              child: Icon(Icons.priority_high_rounded,
                  size: 18, color: os.onDanger),
            ),
            const SizedBox(width: OSSpace.sm),
            Text('Export failed',
                style: OSTypography.subtitle.copyWith(color: os.onSurface)),
          ],
        ),
        const SizedBox(height: OSSpace.xs),
        Text(_errorMessage ?? '',
            style: OSTypography.body.copyWith(color: os.onSurfaceVariant)),
        const SizedBox(height: OSSpace.md),
        OSButton(
          label: 'Try again',
          kind: OSButtonKind.tonal,
          expand: true,
          onPressed: () => setState(() => _stage = _Stage.idle),
        ),
      ],
    );
  }
}

class _QualityOption extends StatelessWidget {
  const _QualityOption({
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: OSSpace.xs + 2),
        decoration: BoxDecoration(
          color: selected ? os.accentContainer : os.surfaceVariant,
          borderRadius: BorderRadius.circular(OSRadius.chip),
          border: Border.all(color: selected ? os.accent : os.outline),
        ),
        child: Column(
          children: [
            Text(label,
                style: OSTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? os.onAccentContainer : os.onSurface,
                )),
            const SizedBox(height: 2),
            Text(hint,
                style: OSTypography.caption.copyWith(
                  fontSize: 10,
                  color:
                      selected ? os.onAccentContainer : os.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(OSRadius.chip),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: OSTypography.body.copyWith(color: os.onSurface)),
            ),
            Text(value,
                style: OSTypography.label.copyWith(
                  fontWeight: FontWeight.w700,
                  color: onTap == null ? os.onSurfaceVariant : os.accent,
                )),
            if (onTap != null)
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: os.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
