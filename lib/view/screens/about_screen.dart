import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:openscan/view/extensions.dart';
// import 'package:flutter_neumorphic/flutter_neumorphic.dart' as neumorphic;
import 'package:url_launcher/url_launcher.dart';

void launchWebsite(Uri url) async {
  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    print("Couldn't launch the url");
  }
}

class AboutScreen extends StatelessWidget {
  static String route = "AboutScreen";
  final String vjLink = "https://www.linkedin.com/in/vijay-t-s/";
  final String vikramLink = "https://www.linkedin.com/in/vikram-harikrishnan/";

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Theme.of(context).primaryColor,
          title: RichText(
            text: TextSpan(
              text: AppLocalizations.of(context)!.about,
              style: TextStyle().appBarStyle,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
                    padding: EdgeInsets.fromLTRB(15, 8, 0, 8),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: ListView(
          padding: EdgeInsets.all(20.0),
          children: <Widget>[
            Center(
              child: Image.asset(
                'assets/scan_g.jpeg',
                scale: 6,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: RichText(
                textAlign: TextAlign.justify,
                text: TextSpan(
                  text: 'Open',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  children: [
                    TextSpan(
                        text: 'Scan ',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary)),
                    TextSpan(
                      text:
                          AppLocalizations.of(context)!.app_description,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            Center(
              child: Text(
                AppLocalizations.of(context)!.developers,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(
              height: size.height * 0.02,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                // ContactCard(
                //   name: "Vijay",
                //   link: vjLink,
                //   image: AssetImage('assets/vj_jpg.JPG'),
                // ),
                // ContactCard(
                //   name: "Vikram",
                //   link: vikramLink,
                //   image: AssetImage('assets/vikkiboi.jpg'),
                // ),
              ],
            ),
            SizedBox(
              height: size.height * 0.03,
            ),
            Center(
              child: Text(
                AppLocalizations.of(context)!.app_description_2,
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: size.height * 0.035,
            ),
            Center(
              child: GestureDetector(
                onTap: () => launchWebsite(
                  Uri.dataFromString('https://github.com/Ethereal-Developers-Inc/OpenScan'),
                ),
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 2, 7, 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(bottom: 5.0),
                          child: Image.asset(
                            'assets/github-sign.png',
                            scale: 3.5,
                          ),
                        ),
                        Text(
                          "OPEN SOURCED ON\n GITHUB",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: AppLocalizations.of(context)!.version,
                style: TextStyle(fontSize: 14),
                children: [
                  TextSpan(
                    text: ' 3.0.0',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: size.height * 0.01,
            ),
          ],
        ),
      ),
    );
  }
}

// class ContactCard extends StatelessWidget {
//   final String link;
//   final String name;
//   final AssetImage image;

//   const ContactCard({this.link, this.name, this.image});

//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.of(context).size;
//     return neumorphic.NeumorphicButton(
//       onPressed: () => launchWebsite(link),
//       style: neumorphic.NeumorphicStyle(
//         shape: neumorphic.NeumorphicShape.concave,
//         color: AppTheme.backgroundColor,
//         shadowLightColor: Colors.grey[600],
//         shadowDarkColor: Colors.black87,
//         boxShape: neumorphic.NeumorphicBoxShape.roundRect(BorderRadius.circular(10)),
//       ),
//       padding: EdgeInsets.all(0),
//       child: Container(
//         padding: EdgeInsets.all(8.0),
//         height: size.width * 0.45,
//         width: size.width * 0.4,
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: <Widget>[
//             CircleAvatar(
//               backgroundColor: Theme.of(context).colorScheme.secondary,
//               radius: size.width * 0.13,
//               backgroundImage: image,
//             ),
//             Padding(
//               padding: const EdgeInsets.fromLTRB(0, 8.0, 0, 0),
//               child: Text(
//                 name,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//               ),
//             ),
//             Text(
//               'Tap for more',
//               style: TextStyle(color: Colors.grey[700], fontSize: 12),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
