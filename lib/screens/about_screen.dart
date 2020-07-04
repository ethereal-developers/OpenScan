import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:openscan/Utilities/constants.dart';
import 'package:url_launcher/url_launcher.dart';

void launchWebsite(String urlString) async {
  if (await canLaunch(urlString)) {
    await launch(urlString);
  } else {
    print("Couldn't launch the url");
  }
}

class AboutScreen extends StatelessWidget {
  static String route = "AboutScreen";
  final String vjlink = "https://github.com/veejayts";
  final String vikramlink = "https://www.linkedin.com/in/vikram-harikrishnan/";

  @override
  Widget build(BuildContext context) {
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
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
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
                child: RichText(
                  textAlign: TextAlign.justify,
                  text: TextSpan(
                    text: 'Open',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    children: [
                      TextSpan(
                          text: 'Scan',
                          style: TextStyle(color: secondaryColor)),
                      TextSpan(
                        text:
                            ' is an open-source app which enables user to scan hard copies of documents and convert it into a PDF file.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      //TODO: Content Writing
                      TextSpan(
                        text:
                            '\n                               Add more content',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ],
                  ),
                ),
              ),
              Spacer(
                flex: 3,
              ),
              Center(
                child: Text(
                  "Developers",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  ContactCard(
                    name: "Vijay",
                    link: vjlink,
                    image: AssetImage('assets/vj.jpg'),
                  ),
                  ContactCard(
                    name: "Vikram",
                    link: vikramlink,
                    image: AssetImage('assets/vikkiboi.jpg'),
                  ),
                ],
              ),
              Spacer(
                flex: 2,
              ),
              Center(
                child: Text(
                  "No ads. We don't collect any data.\n We respect your privacy.",
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              Spacer(),
              Center(
                child: GestureDetector(
                  onTap: () =>
                      launchWebsite('https://github.com/veejayts/openscan'),
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

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () => launchWebsite(link),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(10),
          ),
        ),
        elevation: 10.0,
        child: Container(
          margin: EdgeInsets.all(8.0),
          height: size.width * 0.35,
          width: size.width * 0.35,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              CircleAvatar(
                backgroundColor: secondaryColor,
                radius: size.width * 0.13,
                backgroundImage: image,
              ),
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
