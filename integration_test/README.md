# On-device flow tests

These run the real app on a connected phone, driving the real widget tree
against the real filesystem and the real database:

```
flutter test integration_test/ -d <device-id>          # all of them
flutter test integration_test/crop_flow_test.dart -d <device-id>
```

`flutter devices` lists the ids. The first run of a session pays for a
Gradle build; after that a whole file is seconds.

**Grant the permissions once per install**, or the library screen will sit
behind an Android dialog that these tests cannot tap:

```
integration_test/tools/grant_permissions.sh
```

## What's covered

| File | Flow |
|---|---|
| `library_flow_test.dart` | Empty state, the document grid, search, opening a document, rename, select and delete, the overflow sheet |
| `document_flow_test.dart` | Page grid and numbering, the page preview, deleting a page, re-cropping one, applying a filter |
| `crop_flow_test.dart` | Rotate, No crop, backing out, dragging a corner — each checked against the file that comes back |
| `settings_flow_test.dart` | The scanning switches, auto-capture sharing its key with the camera, default filter, theme |
| `live_scan_flow_test.dart` | The camera's controls and toggles, and what an empty session hands back |

`helpers.dart` seeds documents through the app's own data layer, so what a
test reads is what a scan would have written.

## What can't be covered here, and why

`integration_test` drives the Flutter widget tree. Anything **Android**
draws belongs to another process and cannot be tapped — a test that walks
into one hangs there:

- the camera and storage permission dialogs (hence the grant script)
- the gallery picker, so importing pages can only be tested from the point
  the files are already in hand
- the system share sheet at the end of an export

Two more things are deliberately left to other kinds of test:

- **What a capture produces.** The phone photographs whatever it is
  pointed at, so there is no known page to detect and no result to assert
  on. The detection pipeline is covered by `test/cv/`, where the frames
  are synthetic and the expected quad is known.
- **Reordering pages by dragging.** A long-press drag across a reorderable
  wrap is timing-dependent enough to be a flake generator; the cubit's
  index rewriting is better checked directly.

If you need the native half driven too, that's what
[Patrol](https://pub.dev/packages/patrol) is for — it wraps
`integration_test` and adds UIAutomator on top.
