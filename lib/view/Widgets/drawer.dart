import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:openscan/view/screens/about_screen.dart';
import 'package:openscan/view/screens/demo_screen.dart';

class CustomDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      width: size.width * 0.55,
      color: Theme.of(context).colorScheme.primary,
      child: Column(
        children: <Widget>[
          Spacer(),
          Image.asset(
            'assets/scan_g.jpeg',
            scale: 6,
          ),
          Spacer(),
          Divider(
            thickness: 0.2,
            indent: 6,
            endIndent: 6,
            color: Colors.white24,
          ),
          ListTile(
            title: Center(
              child: Text(
                AppLocalizations.of(context)!.home,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            onTap: () => Navigator.pop(context),
          ),
          Divider(
            thickness: 0.2,
            indent: 6,
            endIndent: 6,
            color: Colors.white24,
          ),
          ListTile(
            title: Center(
              child: Text(
                AppLocalizations.of(context)!.about,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AboutScreen.route);
            },
          ),
          Divider(
            thickness: 0.2,
            indent: 6,
            endIndent: 6,
            color: Colors.white24,
          ),
          ListTile(
            title: Center(
              child: Text(
                AppLocalizations.of(context)!.demo,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DemoScreen(
                    showSkip: false,
                  ),
                ),
              );
            },
          ),
          Divider(
            thickness: 0.2,
            indent: 6,
            endIndent: 6,
            color: Colors.white24,
          ),
          Spacer(
            flex: 4,
          ),
          IconButton(
            icon: Icon(Icons.arrow_back_ios),
            padding: EdgeInsets.fromLTRB(15, 8, 0, 8),
            onPressed: () => Navigator.pop(context),
            color: Theme.of(context).colorScheme.secondary,
          ),
          Spacer(),
        ],
      ),
    );
  }
}
