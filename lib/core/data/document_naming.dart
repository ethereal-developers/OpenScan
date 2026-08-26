/// How documents are named when the user has not named them.
///
/// A document's folder name is also its identity: it is what the library
/// shows for an unnamed document, what an export is filed under, and —
/// because the folder is created before the database row exists — where
/// the created timestamp is read back from.
library;

/// The name a document gets when it is created: `OpenScan-2026-08-26-…`,
/// ending in [DateTime.millisecondsSinceEpoch].
///
/// The date is there to be read and the epoch stamp to be unique — two
/// documents started in the same second still get different folders, and
/// the whole name is safe on every filesystem an export can land on. The
/// previous scheme, `OpenScan 2026-08-26 22:29:11.375905`, was neither:
/// it carried spaces and colons, and colons are illegal on FAT and exFAT
/// volumes, which is exactly where an SD card or a USB drive lands.
String defaultDocumentName(DateTime at) {
  final month = at.month.toString().padLeft(2, '0');
  final day = at.day.toString().padLeft(2, '0');
  return 'OpenScan-${at.year}-$month-$day-${at.millisecondsSinceEpoch}';
}

/// The moment a document named [name] was created, or null if the name
/// does not carry one — a name the user chose, or something unrecognised.
///
/// Reads both schemes. Documents scanned before the rename keep their old
/// folder names on disk (renaming a folder means rewriting every page path
/// that points into it, for a cosmetic gain), so the old shape has to stay
/// readable indefinitely, not just across one upgrade.
DateTime? createdFromDocumentName(String name) {
  final current = RegExp(r'^OpenScan-\d{4}-\d{2}-\d{2}-(\d+)$').firstMatch(name);
  if (current != null) {
    final millis = int.tryParse(current.group(1)!);
    if (millis != null) return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  // Legacy: 'OpenScan <ISO 8601>', the DateTime's own toString().
  if (name.startsWith('OpenScan ')) {
    return DateTime.tryParse(name.substring('OpenScan '.length));
  }
  return null;
}

/// Whether [name] is one this app generated rather than one the user
/// chose, in either scheme. An unnamed document is filed under its own
/// name; a named one is filed under the name it was given.
bool isGeneratedDocumentName(String name) =>
    createdFromDocumentName(name) != null;

/// The filename an export of [documentName] is filed under, without an
/// extension.
///
/// A document the user named is filed under that name, stripped to
/// characters every filesystem accepts. One they never named — or one
/// whose name survives stripping as nothing at all — is filed under a
/// freshly generated [defaultDocumentName], unique by construction, so
/// repeated exports of an unnamed document do not overwrite each other.
String exportFileName(String documentName, {DateTime? now}) {
  if (isGeneratedDocumentName(documentName)) {
    return defaultDocumentName(now ?? DateTime.now());
  }
  final cleaned = documentName
      .replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');
  return cleaned.isEmpty ? defaultDocumentName(now ?? DateTime.now()) : cleaned;
}
