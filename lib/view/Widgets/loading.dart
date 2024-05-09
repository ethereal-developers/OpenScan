import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:openscan/view/extensions.dart';

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
                    AppLocalizations.of(context)!.loading + '...',
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
