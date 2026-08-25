import 'package:flutter/material.dart';
import 'package:openscan/core/data/database_helper.dart';
import 'package:openscan/core/theme/os_colors.dart';
import 'package:openscan/core/theme/os_tokens.dart';
import 'package:openscan/core/theme/os_typography.dart';

/// Rename, following the canonical dialog spec: title, one field, cancel +
/// confirm. The field opens with the current name selected, so the common
/// case (replace it entirely) is one keystroke.
class RenameDialog extends StatefulWidget {
  const RenameDialog({
    Key? key,
    required this.onConfirm,
    required this.fileName,
    required this.docTableName,
  }) : super(key: key);

  final void Function(String) onConfirm;
  final String fileName;
  final String docTableName;

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  final DatabaseHelper database = DatabaseHelper();
  final TextEditingController _controller = TextEditingController();
  String? errorText;

  late String newName;

  @override
  void initState() {
    super.initState();
    newName = widget.fileName;
    _controller.text = newName;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    newName = newName.trim();
    if (newName.isEmpty) {
      setState(() => errorText = 'File name cannot be empty');
      return;
    }
    if (newName.contains(RegExp(r'[/.]'))) {
      setState(() => errorText = 'Special characters are not allowed');
      return;
    }
    database.renameDirectory(
      tableName: widget.docTableName,
      newName: newName,
    );
    Navigator.pop(context);
    widget.onConfirm(newName);
  }

  @override
  Widget build(BuildContext context) {
    final os = context.os;
    return AlertDialog(
      backgroundColor: os.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OSRadius.sheet),
      ),
      title: Text('Rename file',
          style: OSTypography.subtitle.copyWith(color: os.onSurface)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        // Selecting the whole name on focus makes "type a new name" the
        // default gesture rather than "edit the timestamp OpenScan made up".
        onTap: () => _controller.selection = TextSelection(
            baseOffset: 0, extentOffset: _controller.value.text.length),
        onChanged: (value) => newName = value,
        onSubmitted: (_) => _save(),
        textCapitalization: TextCapitalization.words,
        style: OSTypography.body.copyWith(color: os.onSurface),
        decoration: InputDecoration(
          errorText: errorText,
          errorStyle: OSTypography.caption.copyWith(color: os.danger),
        ),
      ),
      actionsPadding:
          const EdgeInsets.fromLTRB(OSSpace.sm, 0, OSSpace.sm, OSSpace.sm),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: OSTypography.label.copyWith(
                  fontWeight: FontWeight.w700, color: os.onSurfaceVariant)),
        ),
        TextButton(
          onPressed: _save,
          child: Text('Save',
              style: OSTypography.label
                  .copyWith(fontWeight: FontWeight.w700, color: os.accent)),
        ),
      ],
    );
  }
}
