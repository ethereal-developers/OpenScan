import 'package:flutter/material.dart';

class DeleteDialog extends StatelessWidget {
  final Function cancelOnPressed;
  final Function deleteOnPressed;
  DeleteDialog({
    this.cancelOnPressed,
    this.deleteOnPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      title: Text('Delete'),
      content: Text('Do you really want to delete this file?'),
      actions: <Widget>[
        TextButton(
          onPressed: cancelOnPressed,
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        TextButton(
          onPressed: deleteOnPressed,
          child: Text(
            'Delete',
            style: TextStyle(
              color: Colors.redAccent,
            ),
          ),
        ),
      ],
    );
  }
}
