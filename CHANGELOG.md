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

### Changed

- Cropping and edge detection are pure Dart; the OpenCV dependency is gone.
- Captures are stored through the platform's own image decoder, which
  decodes and downscales in one native step instead of several seconds of
  pure-Dart work per page.
- The database moved from a table-per-document schema to `documents` +
  `pages`, migrated automatically on first launch.
- Export quality is now a compression scale, and an export is named after
  its document.
- Rebuilt the interface on a warm-white, single-accent design system.
- targetSdk 36, scoped storage, Java 17.

### Fixed

- Live scan no longer fails to reopen the camera after backgrounding.
- Exposure +/- no longer only ever increases on Android.
- Rotate turns the saved page and its detected outline, not just the
  preview.
- Crop handles stay clear of the system back-gesture strip.
- Pages the app cannot draw are no longer kept, and exports no longer
  leave files the user cannot delete.

### Removed

- `RECORD_AUDIO`, `READ_MEDIA_AUDIO`, `READ_MEDIA_VIDEO` and
  `READ_MEDIA_IMAGES`, which dependencies declared but OpenScan never
  used.
- The storage permission request, made redundant by scoped storage.

### Known limitations

- The Greek, Hungarian and Polish translations cover only part of the
  interface; most strings are still English.

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
