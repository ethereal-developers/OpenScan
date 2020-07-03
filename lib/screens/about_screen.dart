import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:openscan/Utilities/constants.dart';
import 'package:openscan/screens/home_screen.dart';
// import 'package:url_launcher/url_launcher.dart' as url;

class AboutScreen extends StatelessWidget {
  static String route = "AboutScreen";
  final String vjlink = "https://github.com/veejayts";
  final String vikramlink = "https://github.com/vikram0230";

  // TODO: fix dumb bug
  // void lauchWebsite(String urlString) async {
  //   if (await url.canLaunch(urlString)) {
  //     await url.launch(urlString);
  //   } else {
  //     print("Couldn't lauch the url");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        backgroundColor: primaryColor,
        appBar: AppBar(
          elevation: 0,
          centerTitle: true,
          backgroundColor: primaryColor,
          title: RichText(
            text: TextSpan(
              text: 'About',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
            ),
          ),
//          leading: IconButton(
//            icon: Icon(Icons.arrow_back_ios),
//            onPressed: () => Navigator.pop(context),
//          ),
        ),
        drawer: Container(
          width: size.width * 0.6,
          color: primaryColor,
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
                color: Colors.white,
              ),
              ListTile(
                title: Center(
                  child: Text(
                    'Home',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                onTap: () => Navigator.popUntil(context, ModalRoute.withName(HomeScreen.route)),
              ),
              Divider(
                thickness: 0.2,
                indent: 6,
                endIndent: 6,
                color: Colors.white,
              ),
              ListTile(
                title: Center(
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                onTap: () {},
              ),
              Divider(
                thickness: 0.2,
                indent: 6,
                endIndent: 6,
                color: Colors.white,
              ),
              ListTile(
                title: Center(
                  child: Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              Divider(
                thickness: 0.2,
                indent: 6,
                endIndent: 6,
                color: Colors.white,
              ),
              Spacer(
                flex: 10,
              ),
              IconButton(
                icon: Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.pop(context),
                color: secondaryColor,
              ),
              Spacer(),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Image.asset(
                  'assets/scan_g.jpeg',
                  scale: 6,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  "OpenScan is an open-source application which enables user to scan hard copies of documents and convert it into a PDF file.",
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 15
                  ),
                ),
              ),
              Text(
                "No ads. We don't collect any data. We respect your privacy.",
                style: TextStyle(
                    fontSize: 14
                ),
              ),
              Spacer(flex: 3,),
              Text(
                "Developed by:",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600
                ),
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  ContactCard(
                    name: "Vijay",
                    link: vjlink,
                    // TODO: Use a different image
                    image: AssetImage('assets/vj.jpg'),
                  ),
                  ContactCard(
                    name: "Vikram",
                    link: vikramlink,
                    image: AssetImage('assets/vikkiboi.jpg'),
                  ),
                ],
              ),
              Spacer(flex: 4,),
              Center(
                // TODO: Use a list tile
                child: RaisedButton(
                  color: secondaryColor,
                  child: Row(
                    children: <Widget>[
                      Image.asset('assets/github-sign.png', scale: 10,),
                      Text("OPEN SOURCED ON\n GITHUB",
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  onPressed: () {
                    // lauchWebsite('https://github.com/veejayts/openscan');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactCard extends StatelessWidget {
  final String link;
  final String name;
  final AssetImage image;

  const ContactCard({Key key, this.link, this.name, this.image});

  // void lauchWebsite(String urlString) async {
  //   if (await url.canLaunch(urlString)) {
  //     await url.launch(urlString);
  //   } else {
  //     print("Couldn't lauch the url");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10.0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: () {
            // lauchWebsite("$link");
          },
          child: Container(
            height: 150.0,
            width: 150.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                CircleAvatar(
                  // TODO: add image
                  backgroundColor: Colors.blueAccent,
                  minRadius: 20.0,
                  maxRadius: 45.0,
                  backgroundImage: image,
                ),
                Text(
                  "Tap to View $name on GitHub",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
