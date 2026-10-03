# v3.0.0

A full rewrite of the scanning pipeline, the camera, and the UI.

### Added

- Live document detection: edges are found in the viewfinder and the page
  is captured and cropped to them automatically.
- Six document filter modes (replacing the old photo filters), applied to
  one page or the whole document.
- Camera controls: pinch-to-zoom slider, tap-to-focus and -expose, manual
  exposure, and a front/back switch.
- On-device integration tests covering the capture, crop, library,
  settings and export flows, plus a database migration test.
- Tamil and Hindi translations. The interface is now fully translated
  in English, Greek, Hindi, Hungarian, Polish and Tamil, with plural
  forms and dates that follow the locale.
- The About screen credits both developers again, as v2 did, with a card
  each linking to their LinkedIn.
- The tutorial is now a walkthrough of the app: six slides covering
  auto-capture, multi-page scanning, edge adjustment and filters, page
  reordering, and export, each with a working miniature of the screen it
  describes that animates the gesture being taught.

### Changed

- The tutorial's illustrations are drawn from the theme's own tokens
  rather than shipped as screenshots, so they follow the chosen accent and
  cannot go stale against the screens they depict.
- Each page is processed the moment its shutter fires — cropped to the
  detected boundary and re-encoded while the shutter shows a spinner —
  instead of the whole batch being processed after Done, so finishing a
  session is instant however many pages it holds.
- Cropping and edge detection are pure Dart; the OpenCV dependency is gone.
- Captures are stored through the platform's own image decoder, which
  decodes and downscales in one native step instead of several seconds of
  pure-Dart work per page.
- The database moved from a table-per-document schema to `documents` +
  `pages`, migrated automatically on first launch.
- Export quality is now a compression scale, and an export is named after
  its document.
- Rebuilt the interface on a warm-white, single-accent design system, with
  matching light and dark themes and a system/light/dark switch in Settings.
- targetSdk 36, scoped storage, Java 17.

### Fixed

- Live scan no longer fails to reopen the camera after backgrounding.
- Exposure +/- no longer only ever increases on Android.
- Rotate turns the saved page and its detected outline, not just the
  preview.
- Crop handles stay clear of the system back-gesture strip.
- Pages the app cannot draw are no longer kept, and exports no longer
  leave files the user cannot delete.
- The tutorial's back button, opened from Settings, sat in the top-right
  corner where Skip belongs; it is now on the leading edge.
- Every outbound link works again. Android 11+ package visibility hid all
  browsers from `canLaunchUrl`, so the About screen's GitHub button did
  nothing at all; the manifest now declares the browser query, and a link
  that still cannot open says so instead of only logging.
- The About screen's description no longer opens mid-sentence: every
  locale writes it to follow the app's name inline, and the name had been
  dropped from the paragraph.
- Tutorial slides no longer overflow on short screens or at large text
  sizes — the copy used to be pushed off the bottom, in every language at
  200% text.

### Removed

- `RECORD_AUDIO`, `READ_MEDIA_AUDIO`, `READ_MEDIA_VIDEO` and
  `READ_MEDIA_IMAGES`, which dependencies declared but OpenScan never
  used.
- The storage permission request, made redundant by scoped storage.

# v2.2.0

### Changed

- Reduce margins during PDF export
- Export location by default is Documents/OpenScan/PDF
- Multi image picker UI
- Change default export quality

### Fixed

- Image quality increased with lower file sizes
- Improved edge detection
- BW filter upgraded
- Quick action icons show actual icons instead of generic icons

# v2.1.0

### Changed

- Icon changes
- Animation in floating action button
- Remove margins during PDF export
- Storage location default to in app directory

### Added

- Multiple image picker
- Quick action

### Fixed

- File rename checker

### Removed

- Delete all option from export menu

# v2.0.0

### Changed

- New Cropper with more advanced functions
- Demo images
- Export of files no longer has the 'OpenScan' appended to it

### Added

- Quick Scan feature
- Camera permission request
- Rename of documents
- Reorder of images
- Selective export of images
- Selective delete of images
- Image preview of documents in Home Screen
- Document Compressor and/or Quality selector for exporting documents

### Fixed

- HomeScreen update after deleting file
- Clear temporary images after adding images in View Document screen
- Camera access on older devices
- Picture folder Hidden
- Document not saving for Android 11

### Removed

- Previous scanner
- Support for iOS removed
- Scan Document screen removed. Now directly goes directly to View Document.

# v1.0.0 - 13/07/2020

### Added

- Save as PDF
- Share as PDF
- Share as Images
- Preview PDF
- Cropping Features
