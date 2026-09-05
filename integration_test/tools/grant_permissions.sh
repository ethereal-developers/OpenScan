#!/usr/bin/env bash
# Grants the runtime permissions the app asks for on launch, so the
# on-device flow tests aren't blocked by an Android dialog they have no
# way to tap. Run once per install (a reinstall clears the grants).
#
# Usage: integration_test/tools/grant_permissions.sh [device-id]
set -euo pipefail

PACKAGE=com.ethereal.openscan
DEVICE_ARGS=()
if [[ $# -gt 0 ]]; then
  DEVICE_ARGS=(-s "$1")
fi

for permission in \
  android.permission.CAMERA \
  android.permission.READ_EXTERNAL_STORAGE \
  android.permission.WRITE_EXTERNAL_STORAGE
do
  # Not every permission exists on every API level; a missing one is fine.
  adb "${DEVICE_ARGS[@]}" shell pm grant "$PACKAGE" "$permission" 2>/dev/null \
    || echo "skipped $permission"
done

echo "granted for $PACKAGE"
