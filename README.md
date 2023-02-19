<p align="center">
<img src="https://github.com/Ethereal-Developers-Inc/OpenScan/blob/master/assets/scan_g.jpeg" height=300>
</p>

<H1 align='center'> OpenScan </H1>
<H3 align='center'>Reclaim your Privacy</H3>
<br>

An privacy friendly app that enables users to scan hardcopies of documents or notes and convert it to a PDF file. No ads. No data collection. We respect your privacy.

<p align='center'>
<a href="https://play.google.com/store/apps/details?id=com.ethereal.openscan" alt="Get it on Google Play"><img src="https://github.com/Ethereal-Developers-Inc/OpenScan/blob/dev_v3/assets/Playstore.png" width=200></a>
<a href="https://apt.izzysoft.de/fdroid/index/apk/com.ethereal.openscan" alt="Get it on IzzyOnDroid"><img src="https://gitlab.com/IzzyOnDroid/repo/-/raw/master/assets/IzzyOnDroid.png" width=200></a>
<br><br>
(Build instructions present at the bottom of the file)
</p>

# About this app

Our open source document scanner app will enable you to scan anything (official documents, notes, photos, business cards, etc.) and convert it into a PDF file and share it via any messaging app that allows it.

Why use this app?
Sometimes, you require to scan several documents and share them in this fast-paced professional world. Maybe, you want to scan and store your receipts and billing information for filing taxes. In this day and age, we look for not only ease of use in technology, but also apps which respect our data privacy and apps which doesn't force ads on our screen every other second.

We bring you OpenScan, an app which respects your privacy coupled with comprehensive and beautiful user interface and a flawless user experience.

We _differentiate_ our self from the rest of the apps in the market by:

1. **Open Sourcing** our app
2. **Respecting your data privacy** (by not collecting any document data knowingly)

# KEY FEATURES

- Scan your documents, notes, business cards.
- Simple and powerful cropping features.
- Share as PDF/JPGs.

### WORK PRODUCTIVITY:

- Increase your office/work productivity by scanning and saving your documents or notes quickly and share them with anyone.
- Capture your ideas or flowcharts that you jot down hurriedly and upload them to your choice of cloud storage instantly.
- Never forget anyone's contact information by scanning the business cards and storing them.
- Scan printed documents and save them to be reviewed later or send them to your contacts to review it.
- Never worry when it comes to receipts anymore. Just scan the receipts and save them to your device and share them whenever necessary.

### EDUCATIONAL PRODUCTIVITY

- Scan all your handwritten notes and share them instantly to your friends during stressful exam times.
- Never miss another lecture notes. All documents are timestamped, so just look up the date or time of the lecture to quickly bring up the lecture notes.
- Take pictures of the whiteboards or the blackboards for future reference and save those as PDFs.
- Upload your class notes to your choice of cloud storage instantly.

## PACKAGES USED

- flutter_scanner_cropper:
  - git:
    - url: https://github.com/Ethereal-Developers-Inc/flutter-scanner-plugin.git
    - ref: master
    - path: flutter_scanner_cropper/
- cupertino_icons: ^0.1.3
- flutter_speed_dial: ^1.2.5
- focused_menu: ^1.0.1
- image_picker: ^0.8.4
- open_file: ^3.2.1
- path_provider: ^2.0.2
- pdf: ^3.6.0
- permission_handler: ^8.0.1
- quick_actions: ^0.6.0+2
- reorderables: ^0.3.2
- share_extend: ^1.1.9
- shared_preferences: ^0.5.7+3
- simple_animated_icon: ^1.0.0
- sqflite: ^1.3.1+2
- url_launcher: ^6.0.6

# BUILD INSTRUCTIONS

Set up flutter on your local machine [Official Flutter Docs](https://flutter.dev/docs/get-started/install)

Clone this repo on your local machine:

```cmd
git clone https://github.com/Ethereal-Developers-Inc/OpenScan.git
```

### Using Android Studio:

Set up your editor of choice. [Official Flutter Docs for setting up editor](https://flutter.dev/docs/get-started/editor?tab=androidstudio)

- Android Studio
  - Open the project in Android Studio.
  - Make sure that you have your cursor has focused on lib/main.dart (or any other dart file) i.e. just open one of the dart files and click on the (dart) file once.
  - Click on Build > Flutter > Build APK in the menubar at the top of Android Studio.
  - Once the build finshes successfully, in the project folder, go to build > app > outputs > apk > release > app-release.apk
  - This will be your generated apk file which you can install on your phone.

### Using terminal:

- Using the terminal or cmd
  - Make sure you are in the project directory where the pubspec.yaml is present and open your terminal or cmd.
  - Run `flutter build apk`
  - Once the build finshes successfully, in the project folder, go to build > app > outputs > apk > release > app-release.apk
  - This will be your generated apk file which you can install on your phone.

# SCREENSHOTS

<p align="center">
<img src="https://github.com/Ethereal-Developers-Inc/OpenScan/blob/master/assets/home.jpg" height=400>
  <img src="https://github.com/Ethereal-Developers-Inc/OpenScan/blob/master/assets/view_doc_01.jpg" height=400>
    <img src="https://github.com/Ethereal-Developers-Inc/OpenScan/blob/master/assets/view_doc_04.jpg" height=400>
</p>
