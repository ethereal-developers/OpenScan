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
  // bool isEmptyError = false;
  DatabaseHelper database = DatabaseHelper();
  TextEditingController _controller = TextEditingController();
  String? errorText;

  late String newName;

  @override
  void initState() {
    super.initState();
    newName = widget.fileName;
    _controller.text = newName;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      title: Text('Rename File'),
      content: Container(
        width: size.width * 0.7,
        child: Theme(
          data: ThemeData(
            textTheme: TextTheme(),
            textSelectionTheme: TextSelectionThemeData(
              selectionColor: Theme.of(context).colorScheme.secondary,
              cursorColor: Theme.of(context).colorScheme.secondary,
              selectionHandleColor: Theme.of(context).colorScheme.secondary,
            ),
          ),
          child: TextField(
            onTap: () => _controller.selection = TextSelection(
                baseOffset: 0, extentOffset: _controller.value.text.length),
            controller: _controller,
            onChanged: (value) {
              newName = value;
            },
            style: TextStyle(color: Colors.white),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              // prefixStyle: TextStyle(color: Colors.white),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Theme.of(context).colorScheme.secondary),
              ),
              errorText: errorText,
            ),
          ),
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
            if (newName.isEmpty) {
              setState(() {
                errorText = 'Error! File name cannot be empty';
              });
            } else if (newName.contains(RegExp(r'[/.]'))) {
              setState(() {
                errorText = 'Error! Special characters not allowed';
              });
            } else {
              database.renameDirectory(
                tableName: widget.docTableName,
                newName: newName,
              );
              Navigator.pop(context);
              widget.onConfirm(newName);
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
