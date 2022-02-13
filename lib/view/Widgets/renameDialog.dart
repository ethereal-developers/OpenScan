import 'package:flutter/material.dart';
import 'package:openscan/core/data/database_helper.dart';

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
  bool isEmptyError = false;
  DatabaseHelper database = DatabaseHelper();
  TextEditingController _controller = TextEditingController();

  late String newName;

  @override
  void initState() {
    super.initState();
    newName = widget.fileName;
    _controller.text = newName;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      title: Text('Rename File'),
      content: TextField(
        controller: _controller,
        onChanged: (value) {
          newName = value;
        },
        cursorColor: Theme.of(context).colorScheme.secondary,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          prefixStyle: TextStyle(color: Colors.white),
          focusedBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.secondary),
          ),
          errorText: isEmptyError ? 'Error! File name cannot be empty' : null,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.white),
          ),
        ),
        TextButton(
          onPressed: () {
            newName = newName.trim();
            newName = newName.replaceAll('/', '');
            if (newName.isNotEmpty) {
              database.renameDirectory(
                tableName: widget.docTableName,
                newName: newName,
              );
              Navigator.pop(context);
              widget.onConfirm(newName);
            } else {
              setState(() {
                isEmptyError = true;
              });
            }
          },
          child: Text(
            'Save',
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
        ),
      ],
    );
  }
}
