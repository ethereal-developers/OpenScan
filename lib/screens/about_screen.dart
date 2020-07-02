import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:openscan/Utilities/constants.dart';
import 'package:url_launcher/url_launcher.dart' as url;

class AboutScreen extends StatelessWidget {
  final String route = "AboutScreen";
  final String vjlink = "https://github.com/veejayts";
  final String vikramlink = "https://github.com/vikram0230";

  // TODO: fix dumb bug
  void lauchWebsite(String urlString) async {
    if (await url.canLaunch(urlString)) {
      await url.launch(urlString);
    } else {
      print("Couldn't lauch the url");
    }
  }

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
        ),
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  "OpenScan is an open-source app that enables users to scan hard copies of documents or notes and covert it into a PDF file.",
                  textAlign: TextAlign.center,
                ),
              ),
              Text(
                "No ads. We don't collect any data. We respect your privacy.",
              ),
              Padding(
                padding: const EdgeInsets.only(top: 50.0, bottom: 15.0),
                child: Text(
                  "Developed by:",
                ),
              ),
              Row(
                children: <Widget>[
                  ContactCard(
                    name: "Vijay",
                    link: vjlink,
                  ),
                  ContactCard(
                    name: "Vikram",
                    link: vikramlink,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: RaisedButton(
                  color: ThemeData.dark().primaryColor,
                  child: Text("Checkout the Source Code here"),
                  onPressed: () {
                    lauchWebsite('https://github.com/veejayts/openscan');
                  },
                ),
              ),
            ],
          ),
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
              MenuButton(text: 'Menu', size: size),
              MenuButton(text: 'Settings', size: size),
              MenuButton(text: 'About', size: size),
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
      ),
    );
  }
}

class MenuButton extends StatelessWidget {
  const MenuButton({this.size, this.text});

  final String text;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 0),
          child: GestureDetector(
            onTap: () {},
            child: Container(
              color: primaryColor,
              height: size.height * 0.06,
              alignment: Alignment.center,
              child: Text(
                text,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ),
        Divider(
          thickness: 0.2,
          indent: 6,
          endIndent: 6,
          color: Colors.white,
        ),
      ],
    );
  }
}

class ContactCard extends StatelessWidget {
  final String link;
  final String name;
  final Image avatar;

  const ContactCard({Key key, this.link, this.name, this.avatar});

  void lauchWebsite(String urlString) async {
    if (await url.canLaunch(urlString)) {
      await url.launch(urlString);
    } else {
      print("Couldn't lauch the url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10.0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: () {
            lauchWebsite("$link");
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
