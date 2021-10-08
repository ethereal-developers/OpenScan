import 'package:flutter/material.dart';
import 'package:openscan/presentation/extensions.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      elevation: 30,
      backgroundColor: Colors.transparent,
      children: [
        Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              // color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.secondary,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Loading...',
                    style: TextStyle().appBarStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
